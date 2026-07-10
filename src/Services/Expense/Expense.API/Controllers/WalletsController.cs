using Expense.API.Data;
using Expense.API.Domain.Entities;
using Expense.API.Domain.Enums;
using Expense.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses/wallets")]
public class WalletsController : ControllerBase
{
    private readonly ExpenseDbContext _dbContext;
    private readonly WalletLedgerService _walletLedger;

    public WalletsController(ExpenseDbContext dbContext, WalletLedgerService walletLedger)
    {
        _dbContext = dbContext;
        _walletLedger = walletLedger;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpPost]
    public async Task<IActionResult> CreateWallet([FromBody] CreateWalletRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        var existing = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.TripId == request.TripId, ct);

        if (existing is not null)
        {
            return Ok(WalletResponse.From(existing));
        }

        var wallet = new TripWallet
        {
            TripId = request.TripId,
            Name = string.IsNullOrWhiteSpace(request.Name) ? "Trip wallet" : request.Name.Trim(),
            Currency = (request.Currency ?? "VND").ToUpperInvariant(),
            CurrentCustodianUserId = request.CurrentCustodianUserId ?? userId
        };

        await _dbContext.TripWallets.AddAsync(wallet, ct);
        await _dbContext.WalletMembers.AddAsync(new WalletMember
        {
            TripWalletId = wallet.Id,
            UserId = wallet.CurrentCustodianUserId.Value,
            Role = WalletMemberRole.Custodian
        }, ct);

        await _dbContext.SaveChangesAsync(ct);
        return Created($"/expenses/wallets/{wallet.Id}", WalletResponse.From(wallet));
    }

    [HttpGet("trip/{tripId:guid}")]
    public async Task<IActionResult> GetByTrip(Guid tripId, CancellationToken ct)
    {
        var wallet = await _dbContext.TripWallets
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.TripId == tripId, ct);

        if (wallet is null)
        {
            return NotFound(new { message = "No wallet exists for this trip yet." });
        }

        var members = await _dbContext.WalletMembers
            .AsNoTracking()
            .Where(m => m.TripWalletId == wallet.Id)
            .OrderByDescending(m => m.Role)
            .ThenBy(m => m.JoinedAt)
            .Select(m => new WalletMemberResponse(m.UserId, m.Role.ToString(), m.ExpectedContribution, m.IsActive))
            .ToListAsync(ct);

        var openFundRequests = await _dbContext.FundRequests
            .AsNoTracking()
            .Where(f => f.TripWalletId == wallet.Id && f.Status == FundRequestStatus.Open)
            .Select(f => new FundRequestSummaryResponse(f.Id, f.Title, f.TargetAmount, f.Currency, f.DueAt))
            .ToListAsync(ct);

        return Ok(new WalletDetailResponse(
            WalletResponse.From(wallet),
            members,
            openFundRequests));
    }

    [HttpGet("{walletId:guid}/transactions")]
    public async Task<IActionResult> GetTransactions(Guid walletId, [FromQuery] int limit = 50, CancellationToken ct = default)
    {
        var transactions = await _dbContext.WalletTransactions
            .AsNoTracking()
            .Where(t => t.TripWalletId == walletId)
            .OrderByDescending(t => t.OccurredAt)
            .Take(Math.Clamp(limit, 1, 200))
            .Select(t => new WalletTransactionResponse(
                t.Id,
                t.TransactionNo,
                t.Type.ToString(),
                t.Direction.ToString(),
                t.Amount,
                t.Currency,
                t.BalanceAfter,
                t.ActorUserId,
                t.CounterpartyUserId,
                t.OccurredAt,
                t.Status.ToString()))
            .ToListAsync(ct);

        return Ok(transactions);
    }

    [HttpPatch("{walletId:guid}/custodian")]
    public async Task<IActionResult> TransferCustodian(Guid walletId, [FromBody] TransferCustodianRequest request, CancellationToken ct)
    {
        var wallet = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.Id == walletId, ct);

        if (wallet is null)
        {
            return NotFound(new { message = "Wallet not found." });
        }

        var previousCustodian = wallet.CurrentCustodianUserId;
        wallet.CurrentCustodianUserId = request.NewCustodianUserId;

        var member = await _dbContext.WalletMembers
            .FirstOrDefaultAsync(m => m.TripWalletId == walletId && m.UserId == request.NewCustodianUserId, ct);

        if (member is null)
        {
            await _dbContext.WalletMembers.AddAsync(new WalletMember
            {
                TripWalletId = walletId,
                UserId = request.NewCustodianUserId,
                Role = WalletMemberRole.Custodian
            }, ct);
        }
        else
        {
            member.Role = WalletMemberRole.Custodian;
            member.IsActive = true;
        }

        await _walletLedger.PostAsync(new WalletPostRequest(
            walletId,
            WalletTransactionType.CustodianTransfer,
            TransactionDirection.Credit,
            0m,
            wallet.Currency,
            GetUserId(),
            request.NewCustodianUserId,
            MetadataJson: $$"""{"previousCustodianUserId":"{{previousCustodian}}","newCustodianUserId":"{{request.NewCustodianUserId}}","note":"{{request.Note}}"}"""), ct);

        return Ok(WalletResponse.From(wallet));
    }
}

public sealed record CreateWalletRequest(Guid TripId, string? Name, string? Currency, Guid? CurrentCustodianUserId);

public sealed record TransferCustodianRequest(Guid NewCustodianUserId, string? Note);

public sealed record WalletResponse(
    Guid WalletId,
    Guid TripId,
    string Name,
    decimal CurrentBalance,
    string Currency,
    decimal TotalContributed,
    decimal TotalSpent,
    Guid? CurrentCustodianUserId,
    string Status)
{
    public static WalletResponse From(TripWallet wallet) => new(
        wallet.Id,
        wallet.TripId,
        wallet.Name,
        wallet.CurrentBalance,
        wallet.Currency,
        wallet.TotalContributed,
        wallet.TotalSpent,
        wallet.CurrentCustodianUserId,
        wallet.Status.ToString());
}

public sealed record WalletDetailResponse(
    WalletResponse Wallet,
    IReadOnlyList<WalletMemberResponse> Members,
    IReadOnlyList<FundRequestSummaryResponse> OpenFundRequests);

public sealed record WalletMemberResponse(Guid UserId, string Role, decimal? ExpectedContribution, bool IsActive);

public sealed record FundRequestSummaryResponse(Guid FundRequestId, string Title, decimal TargetAmount, string Currency, DateTime? DueAt);

public sealed record WalletTransactionResponse(
    Guid WalletTransactionId,
    string TransactionNo,
    string Type,
    string Direction,
    decimal Amount,
    string Currency,
    decimal? BalanceAfter,
    Guid ActorUserId,
    Guid? CounterpartyUserId,
    DateTime OccurredAt,
    string Status);
