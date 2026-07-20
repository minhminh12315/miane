using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.Domain.Enums;
using Expense.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses/vietqr")]
public class VietQrController : ControllerBase
{
    private readonly ExpenseDbContext _dbContext;
    private readonly IVietQrClient _vietQrClient;
    private readonly PaymentAccountProtector _protector;

    public VietQrController(
        ExpenseDbContext dbContext,
        IVietQrClient vietQrClient,
        PaymentAccountProtector protector)
    {
        _dbContext = dbContext;
        _vietQrClient = vietQrClient;
        _protector = protector;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpGet("banks")]
    public async Task<IActionResult> GetBanks([FromQuery] bool transferSupportedOnly = true, CancellationToken ct = default)
    {
        var banks = await _vietQrClient.GetBanksAsync(ct);
        var response = banks
            .Where(bank => !transferSupportedOnly || bank.TransferSupported)
            .Select(bank => new VietQrBankResponse(
                bank.Id,
                bank.Name,
                bank.Code,
                bank.Bin,
                bank.ShortName,
                bank.Logo,
                bank.TransferSupported,
                bank.LookupSupported,
                bank.SwiftCode))
            .ToList();

        return Ok(response);
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateVietQrPaymentRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        var amount = ValidateAmount(request.Amount);
        var addInfo = VietQrTextNormalizer.NormalizeAddInfo(request.AddInfo);

        var receiveAccount = await ResolveReceiveAccountAsync(userId, request, ct);
        return Ok(await GeneratePaymentResponseAsync(receiveAccount, amount, addInfo, request.Format, request.Template, ct));
    }

    [HttpPost("debts/{debtRecordId:guid}/generate")]
    public async Task<IActionResult> GenerateForDebt(
        Guid debtRecordId,
        [FromBody] GenerateVietQrContextRequest request,
        CancellationToken ct)
    {
        var userId = GetUserId();
        var debt = await _dbContext.DebtRecords
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.Id == debtRecordId, ct)
            ?? throw new NotFoundException("khoản nợ", debtRecordId);

        if (debt.IsSettled)
        {
            throw new DomainException("Khoản nợ này đã được đánh dấu là đã thanh toán.", "DEBT_ALREADY_SETTLED");
        }

        if (debt.FromUserId != userId)
        {
            throw new DomainException("Chỉ người đang nợ mới có thể tạo mã VietQR thanh toán khoản nợ này.", "DEBT_PAYMENT_NOT_ALLOWED");
        }

        ValidateVndCurrency(debt.Currency);
        var receiveAccount = await ResolveStoredReceiveAccountAsync(debt.ToUserId, request.PaymentMethodId, ct);
        var addInfo = ResolveTransferInfo(request.AddInfo, $"MIANE TRA NO {ShortCode(debt.Id)}");
        var amount = ValidateAmount(debt.Amount);

        return Ok(await GeneratePaymentResponseAsync(receiveAccount, amount, addInfo, request.Format, request.Template, ct));
    }

    [HttpPost("trips/{tripId:guid}/fund-contribution/generate")]
    public async Task<IActionResult> GenerateForFundContribution(
        Guid tripId,
        [FromBody] GenerateFundContributionVietQrRequest request,
        CancellationToken ct)
    {
        GetUserId();
        ValidateVndCurrency(request.Currency ?? "VND");

        var wallet = await _dbContext.TripWallets
            .AsNoTracking()
            .FirstOrDefaultAsync(item =>
                item.TripId == tripId &&
                item.Status == WalletStatus.Active,
                ct)
            ?? throw new DomainException("Chuyến đi chưa cấu hình thủ quỹ để nhận tiền quỹ.", "TRIP_CUSTODIAN_NOT_CONFIGURED");

        if (!wallet.CurrentCustodianUserId.HasValue)
        {
            throw new DomainException("Chuyến đi chưa cấu hình thủ quỹ để nhận tiền quỹ.", "TRIP_CUSTODIAN_NOT_CONFIGURED");
        }

        var receiveAccount = await ResolveStoredReceiveAccountAsync(wallet.CurrentCustodianUserId.Value, request.PaymentMethodId, ct);
        var addInfo = ResolveTransferInfo(request.AddInfo, $"MIANE NOP QUY {ShortCode(tripId)}");
        var amount = ValidateAmount(request.Amount);

        return Ok(await GeneratePaymentResponseAsync(receiveAccount, amount, addInfo, request.Format, request.Template, ct));
    }

    private async Task<ReceiveAccount> ResolveReceiveAccountAsync(
        Guid userId,
        GenerateVietQrPaymentRequest request,
        CancellationToken ct)
    {
        if (!string.IsNullOrWhiteSpace(request.BankBin) &&
            !string.IsNullOrWhiteSpace(request.AccountNumber) &&
            !string.IsNullOrWhiteSpace(request.AccountName))
        {
            return await ResolveDirectAccountAsync(request, ct);
        }

        return await ResolveStoredReceiveAccountAsync(userId, request.PaymentMethodId, ct);
    }

    private async Task<ReceiveAccount> ResolveStoredReceiveAccountAsync(
        Guid receiveUserId,
        Guid? paymentMethodId,
        CancellationToken ct)
    {
        var query = _dbContext.PaymentMethods
            .AsNoTracking()
            .Where(method =>
                method.UserId == receiveUserId &&
                method.Type == PaymentMethodType.BankAccount &&
                method.Provider == PaymentProvider.VietQr &&
                method.Status == PaymentMethodStatus.Active);

        if (paymentMethodId.HasValue)
        {
            query = query.Where(method => method.Id == paymentMethodId.Value);
        }
        else
        {
            query = query.Where(method => method.IsDefaultReceive);
        }

        var paymentMethod = await query
            .OrderByDescending(method => method.UpdatedAt ?? method.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (paymentMethod is null)
        {
            throw new DomainException("Người nhận chưa cấu hình tài khoản ngân hàng VietQR.", "PAYMENT_METHOD_NOT_CONFIGURED");
        }

        var capabilities = PaymentMethodsController.ReadCapabilities(paymentMethod.CapabilitiesJson);
        var accountNumber = _protector.Unprotect(paymentMethod.BankAccountNoEncrypted);
        if (string.IsNullOrWhiteSpace(accountNumber))
        {
            throw new DomainException("Không thể đọc số tài khoản nhận tiền đã lưu.", "PAYMENT_METHOD_INVALID");
        }

        var bankBin = capabilities?.BankBin ?? paymentMethod.BankCode ?? string.Empty;
        if (!int.TryParse(bankBin, out _))
        {
            throw new DomainException("Mã BIN ngân hàng nhận tiền không hợp lệ.", "PAYMENT_METHOD_INVALID");
        }

        return new ReceiveAccount(
            bankBin,
            capabilities?.VietQrBankCode ?? string.Empty,
            capabilities?.BankName ?? paymentMethod.DisplayName,
            capabilities?.BankShortName ?? paymentMethod.DisplayName,
            accountNumber,
            paymentMethod.BankAccountName ?? string.Empty);
    }

    private async Task<ReceiveAccount> ResolveDirectAccountAsync(
        GenerateVietQrPaymentRequest request,
        CancellationToken ct)
    {
        var normalizedBin = VietQrTextNormalizer.DigitsOnly(request.BankBin ?? string.Empty);
        var banks = await _vietQrClient.GetBanksAsync(ct);
        var bank = banks.FirstOrDefault(item => item.Bin == normalizedBin);
        if (bank is null || !bank.TransferSupported)
        {
            throw new DomainException("Ngân hàng nhận tiền không hỗ trợ VietQR.", "VIETQR_BANK_NOT_SUPPORTED");
        }

        var accountNumber = VietQrTextNormalizer.DigitsOnly(request.AccountNumber ?? string.Empty);
        if (accountNumber.Length is < 6 or > 19)
        {
            throw new DomainException("Số tài khoản VietQR phải gồm 6-19 chữ số.", "INVALID_BANK_ACCOUNT_NUMBER");
        }

        var accountName = VietQrTextNormalizer.NormalizeAccountName(request.AccountName ?? string.Empty);
        if (accountName.Length is < 5 or > 50)
        {
            throw new DomainException("Tên tài khoản VietQR phải có 5-50 ký tự hợp lệ.", "INVALID_BANK_ACCOUNT_NAME");
        }

        return new ReceiveAccount(bank.Bin, bank.Code, bank.Name, bank.ShortName, accountNumber, accountName);
    }

    private async Task<VietQrPaymentResponse> GeneratePaymentResponseAsync(
        ReceiveAccount receiveAccount,
        long amount,
        string addInfo,
        string? format,
        string? template,
        CancellationToken ct)
    {
        var result = await _vietQrClient.GenerateAsync(new VietQrGenerateRequest(
            receiveAccount.AccountNumber,
            receiveAccount.AccountName,
            int.Parse(receiveAccount.BankBin),
            amount,
            addInfo,
            format,
            template), ct);

        return new VietQrPaymentResponse(
            result.QrCode,
            result.QrDataUrl,
            receiveAccount.BankBin,
            receiveAccount.BankCode,
            receiveAccount.BankName,
            receiveAccount.BankShortName,
            receiveAccount.AccountNumber,
            result.AccountName,
            amount,
            addInfo,
            result.Description);
    }

    private static long ValidateAmount(decimal amount)
    {
        if (amount <= 0)
        {
            throw new DomainException("Số tiền tạo VietQR phải lớn hơn 0.", "INVALID_PAYMENT_AMOUNT");
        }

        if (decimal.Truncate(amount) != amount)
        {
            throw new DomainException("VietQR chỉ hỗ trợ số tiền VND nguyên.", "INVALID_PAYMENT_AMOUNT");
        }

        var integerAmount = (long)amount;
        if (integerAmount.ToString().Length > 13)
        {
            throw new DomainException("Số tiền VietQR tối đa 13 chữ số.", "INVALID_PAYMENT_AMOUNT");
        }

        return integerAmount;
    }

    private static void ValidateVndCurrency(string currency)
    {
        if (!string.Equals(currency.Trim(), "VND", StringComparison.OrdinalIgnoreCase))
        {
            throw new DomainException("VietQR hiện chỉ hỗ trợ thanh toán bằng VND.", "VIETQR_CURRENCY_NOT_SUPPORTED");
        }
    }

    private static string ResolveTransferInfo(string? value, string fallback)
    {
        return VietQrTextNormalizer.NormalizeAddInfo(
            string.IsNullOrWhiteSpace(value) ? fallback : value);
    }

    private static string ShortCode(Guid value)
    {
        return value.ToString("N")[..8].ToUpperInvariant();
    }

    private sealed record ReceiveAccount(
        string BankBin,
        string BankCode,
        string BankName,
        string BankShortName,
        string AccountNumber,
        string AccountName);
}

public sealed record VietQrBankResponse(
    int Id,
    string Name,
    string Code,
    string Bin,
    string ShortName,
    string Logo,
    bool TransferSupported,
    bool LookupSupported,
    string? SwiftCode);

public sealed record GenerateVietQrPaymentRequest(
    decimal Amount,
    string? AddInfo,
    Guid? PaymentMethodId,
    string? BankBin,
    string? AccountNumber,
    string? AccountName,
    string? Format,
    string? Template);

public sealed record GenerateVietQrContextRequest(
    string? AddInfo,
    Guid? PaymentMethodId,
    string? Format,
    string? Template);

public sealed record GenerateFundContributionVietQrRequest(
    decimal Amount,
    string? Currency,
    string? AddInfo,
    Guid? PaymentMethodId,
    string? Format,
    string? Template);

public sealed record VietQrPaymentResponse(
    string QrCode,
    string QrDataUrl,
    string BankBin,
    string BankCode,
    string BankName,
    string BankShortName,
    string AccountNumber,
    string AccountName,
    long Amount,
    string AddInfo,
    string Description);
