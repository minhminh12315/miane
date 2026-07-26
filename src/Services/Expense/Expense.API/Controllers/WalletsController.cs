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
[Route("expenses/wallets")]
public class WalletsController : ControllerBase
{
    private readonly ExpenseDbContext _dbContext;
    private readonly WalletLedgerService _walletLedger;
    private readonly WalletAuthorizationService _authz;

    public WalletsController(
        ExpenseDbContext dbContext,
        WalletLedgerService walletLedger,
        WalletAuthorizationService authz)
    {
        _dbContext = dbContext;
        _walletLedger = walletLedger;
        _authz = authz;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpPost]
    public async Task<IActionResult> CreateWallet([FromBody] CreateWalletRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        await _authz.EnsureTripMemberAsync(request.TripId, ct);

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
        await _authz.EnsureTripMemberAsync(tripId, ct);

        var wallet = await _dbContext.TripWallets
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.TripId == tripId, ct);

        if (wallet is null)
        {
            return NotFound(new { message = "Chuyến đi này chưa có ví chung." });
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
        await _authz.EnsureWalletTripMemberAsync(walletId, ct);

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
        var callerId = GetUserId();
        await _authz.EnsureCurrentCustodianAsync(walletId, callerId, ct);

        var wallet = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.Id == walletId, ct)
            ?? throw new NotFoundException("ví chung", walletId);

        await _authz.EnsureTripMemberAsync(wallet.TripId, ct);
        // New custodian must also be a trip member — checked via Trip service for that user
        // by requiring they already appear as a wallet member or we verify trip membership
        // for the new id through a second call with the caller's token can't prove that.
        // Require new custodian already in WalletMembers or same trip: use membership endpoint
        // only for caller. Enforce new custodian is an existing WalletMember or the trip
        // has them as wallet participant after create. Practical rule: new custodian must
        // already be a WalletMember of this wallet.
        var newMember = await _dbContext.WalletMembers
            .FirstOrDefaultAsync(m => m.TripWalletId == walletId && m.UserId == request.NewCustodianUserId, ct);
        if (newMember is null || !newMember.IsActive)
        {
            throw new ForbiddenAccessException(
                "Người nhận quyền giữ ví phải là thành viên ví hiện tại.");
        }

        var previousCustodian = wallet.CurrentCustodianUserId;
        wallet.CurrentCustodianUserId = request.NewCustodianUserId;
        newMember.Role = WalletMemberRole.Custodian;
        newMember.IsActive = true;

        if (previousCustodian is Guid prev && prev != request.NewCustodianUserId)
        {
            var previousMember = await _dbContext.WalletMembers
                .FirstOrDefaultAsync(m => m.TripWalletId == walletId && m.UserId == prev, ct);
            if (previousMember is not null)
            {
                previousMember.Role = WalletMemberRole.Member;
            }
        }

        var metadata = JsonSerializer.Serialize(new
        {
            previousCustodianUserId = previousCustodian,
            newCustodianUserId = request.NewCustodianUserId,
            note = request.Note
        });

        await _walletLedger.PostAsync(new WalletPostRequest(
            walletId,
            WalletTransactionType.CustodianTransfer,
            TransactionDirection.Credit,
            0m,
            wallet.Currency,
            callerId,
            request.NewCustodianUserId,
            MetadataJson: metadata), ct);

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
