using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.Domain.Entities;
using Expense.API.Domain.Enums;
using Expense.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses/payment-methods")]
public class PaymentMethodsController : ControllerBase
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly ExpenseDbContext _dbContext;
    private readonly IVietQrClient _vietQrClient;
    private readonly PaymentAccountProtector _protector;

    public PaymentMethodsController(
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

    [HttpGet("default-receive")]
    public async Task<IActionResult> GetDefaultReceive(CancellationToken ct)
    {
        var userId = GetUserId();
        var paymentMethod = await _dbContext.PaymentMethods
            .AsNoTracking()
            .Where(method =>
                method.UserId == userId &&
                method.IsDefaultReceive &&
                method.Type == PaymentMethodType.BankAccount &&
                method.Provider == PaymentProvider.VietQr &&
                method.Status == PaymentMethodStatus.Active)
            .OrderByDescending(method => method.UpdatedAt ?? method.CreatedAt)
            .FirstOrDefaultAsync(ct);

        return paymentMethod is null
            ? NoContent()
            : Ok(ToResponse(paymentMethod));
    }

    [HttpPut("default-receive")]
    public async Task<IActionResult> SaveDefaultReceive(
        [FromBody] SaveVietQrPaymentMethodRequest request,
        CancellationToken ct)
    {
        var userId = GetUserId();
        var banks = await _vietQrClient.GetBanksAsync(ct);
        var normalizedBin = VietQrTextNormalizer.DigitsOnly(request.BankBin);
        var requestedCode = request.BankCode?.Trim();
        var bank = banks.FirstOrDefault(item =>
            item.Bin == normalizedBin ||
            (!string.IsNullOrWhiteSpace(requestedCode) &&
                string.Equals(item.Code, requestedCode, StringComparison.OrdinalIgnoreCase)));

        if (bank is null)
        {
            throw new DomainException("Ngân hàng không nằm trong danh sách VietQR.", "VIETQR_BANK_NOT_SUPPORTED");
        }

        if (!bank.TransferSupported)
        {
            throw new DomainException("Ngân hàng này chưa hỗ trợ chuyển tiền bằng VietQR.", "VIETQR_TRANSFER_NOT_SUPPORTED");
        }

        var accountNumber = VietQrTextNormalizer.DigitsOnly(request.AccountNumber);
        if (accountNumber.Length is < 6 or > 19)
        {
            throw new DomainException("Số tài khoản VietQR phải gồm 6-19 chữ số.", "INVALID_BANK_ACCOUNT_NUMBER");
        }

        var accountName = VietQrTextNormalizer.NormalizeAccountName(request.AccountName);
        if (accountName.Length is < 5 or > 50)
        {
            throw new DomainException("Tên tài khoản VietQR phải có 5-50 ký tự hợp lệ.", "INVALID_BANK_ACCOUNT_NAME");
        }

        var userMethods = await _dbContext.PaymentMethods
            .Where(method => method.UserId == userId)
            .ToListAsync(ct);

        foreach (var method in userMethods.Where(method => method.IsDefaultReceive))
        {
            method.IsDefaultReceive = false;
            method.UpdatedAt = DateTime.UtcNow;
        }

        var paymentMethod = userMethods.FirstOrDefault(method =>
            method.Type == PaymentMethodType.BankAccount &&
            method.Provider == PaymentProvider.VietQr);

        if (paymentMethod is null)
        {
            paymentMethod = new PaymentMethod
            {
                UserId = userId,
                Type = PaymentMethodType.BankAccount,
                Provider = PaymentProvider.VietQr
            };
            await _dbContext.PaymentMethods.AddAsync(paymentMethod, ct);
        }

        paymentMethod.DisplayName = $"{bank.ShortName} *{accountNumber[^Math.Min(4, accountNumber.Length)..]}";
        paymentMethod.BankCode = bank.Bin;
        paymentMethod.BankAccountNoEncrypted = _protector.Protect(accountNumber);
        paymentMethod.BankAccountName = accountName;
        paymentMethod.IsDefaultReceive = true;
        paymentMethod.Status = PaymentMethodStatus.Active;
        paymentMethod.CapabilitiesJson = JsonSerializer.Serialize(new PaymentMethodCapabilities(
            bank.Bin,
            bank.Code,
            bank.Name,
            bank.ShortName,
            bank.Logo,
            bank.TransferSupported,
            bank.LookupSupported,
            DateTime.UtcNow), JsonOptions);
        paymentMethod.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(ct);

        return Ok(ToResponse(paymentMethod));
    }

    private PaymentMethodResponse ToResponse(PaymentMethod method)
    {
        var capabilities = ReadCapabilities(method.CapabilitiesJson);
        var accountNumber = _protector.Unprotect(method.BankAccountNoEncrypted);

        return new PaymentMethodResponse(
            method.Id,
            method.Provider.ToString(),
            method.Type.ToString(),
            method.DisplayName,
            capabilities?.BankBin ?? method.BankCode ?? string.Empty,
            capabilities?.VietQrBankCode ?? string.Empty,
            capabilities?.BankName ?? string.Empty,
            capabilities?.BankShortName ?? method.DisplayName,
            capabilities?.BankLogoUrl ?? string.Empty,
            accountNumber,
            method.BankAccountName ?? string.Empty,
            method.IsDefaultReceive,
            method.Status.ToString());
    }

    internal static PaymentMethodCapabilities? ReadCapabilities(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<PaymentMethodCapabilities>(json, JsonOptions);
        }
        catch (JsonException)
        {
            return null;
        }
    }
}

public sealed record SaveVietQrPaymentMethodRequest(
    string BankBin,
    string? BankCode,
    string AccountNumber,
    string AccountName);

public sealed record PaymentMethodResponse(
    Guid PaymentMethodId,
    string Provider,
    string Type,
    string DisplayName,
    string BankBin,
    string BankCode,
    string BankName,
    string BankShortName,
    string BankLogoUrl,
    string AccountNumber,
    string AccountName,
    bool IsDefaultReceive,
    string Status);

public sealed record PaymentMethodCapabilities(
    string BankBin,
    string VietQrBankCode,
    string BankName,
    string BankShortName,
    string BankLogoUrl,
    bool TransferSupported,
    bool LookupSupported,
    DateTime VerifiedAtUtc);
