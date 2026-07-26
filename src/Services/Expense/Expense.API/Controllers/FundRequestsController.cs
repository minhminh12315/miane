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
[Route("expenses")]
public class FundRequestsController : ControllerBase
{
    private readonly ExpenseDbContext _dbContext;
    private readonly WalletLedgerService _walletLedger;
    private readonly WalletAuthorizationService _authz;

    public FundRequestsController(
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

    [HttpPost("wallets/{walletId:guid}/fund-requests")]
    public async Task<IActionResult> CreateFundRequest(Guid walletId, [FromBody] CreateFundRequestRequest request, CancellationToken ct)
    {
        var callerId = GetUserId();
        await _authz.EnsureCurrentCustodianAsync(walletId, callerId, ct);

        var wallet = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.Id == walletId, ct)
            ?? throw new NotFoundException("ví chung", walletId);

        if (request.TargetAmount <= 0)
        {
            throw new DomainException("Số tiền mục tiêu của yêu cầu quỹ phải lớn hơn 0.", "INVALID_FUND_TARGET_AMOUNT");
        }

        if (request.Participants.Count == 0)
        {
            throw new DomainException("Yêu cầu quỹ cần ít nhất một người tham gia.", "NO_FUND_PARTICIPANTS");
        }

        var fundRequest = new FundRequest
        {
            TripWalletId = walletId,
            Title = request.Title.Trim(),
            TargetAmount = request.TargetAmount,
            Currency = (request.Currency ?? wallet.Currency).ToUpperInvariant(),
            AllocationType = request.AllocationType,
            DueAt = request.DueAt,
            Status = FundRequestStatus.Open,
            CreatedByUserId = callerId,
            Note = request.Note
        };

        await _dbContext.FundRequests.AddAsync(fundRequest, ct);

        var expectedAmounts = Allocate(request.TargetAmount, request.AllocationType, request.Participants);
        var contributions = expectedAmounts.Select(x => new FundContribution
        {
            FundRequestId = fundRequest.Id,
            TripWalletId = walletId,
            UserId = x.UserId,
            ExpectedAmount = x.Amount,
            Amount = 0m,
            Currency = fundRequest.Currency,
            Status = FundContributionStatus.Pending
        }).ToList();

        await _dbContext.FundContributions.AddRangeAsync(contributions, ct);
        await _dbContext.SaveChangesAsync(ct);

        return Created($"/expenses/fund-requests/{fundRequest.Id}", new FundRequestResponse(
            fundRequest.Id,
            fundRequest.TripWalletId,
            fundRequest.Title,
            fundRequest.TargetAmount,
            fundRequest.Currency,
            fundRequest.AllocationType.ToString(),
            fundRequest.DueAt,
            contributions.Select(c => new FundContributionResponse(c.Id, c.UserId, c.ExpectedAmount, c.Amount, c.Currency, c.Status.ToString())).ToList()));
    }

    [HttpPost("fund-contributions/{contributionId:guid}/confirm")]
    public async Task<IActionResult> ConfirmContribution(Guid contributionId, [FromBody] ConfirmFundContributionRequest request, CancellationToken ct)
    {
        if (request.Amount <= 0)
        {
            throw new DomainException("Số tiền đóng góp phải lớn hơn 0.", "INVALID_CONTRIBUTION_AMOUNT");
        }

        var contribution = await _dbContext.FundContributions
            .Include(c => c.TripWallet)
            .FirstOrDefaultAsync(c => c.Id == contributionId, ct)
            ?? throw new NotFoundException("khoản đóng góp", contributionId);

        if (contribution.Status == FundContributionStatus.Confirmed)
        {
            throw new DomainException("Khoản đóng góp này đã được xác nhận đủ.", "CONTRIBUTION_ALREADY_CONFIRMED");
        }

        var callerId = GetUserId();
        await _authz.EnsureCurrentCustodianAsync(contribution.TripWalletId, callerId, ct);

        contribution.Amount += request.Amount;
        contribution.ConfirmedByUserId = callerId;
        contribution.ConfirmedAt = request.ReceivedAt ?? DateTime.UtcNow;
        contribution.Status = contribution.Amount >= contribution.ExpectedAmount
            ? FundContributionStatus.Confirmed
            : FundContributionStatus.Partial;

        var metadata = JsonSerializer.Serialize(new
        {
            paymentReference = request.PaymentReference,
            proofFileId = request.ProofFileId
        });

        var walletTransaction = await _walletLedger.PostAsync(new WalletPostRequest(
            contribution.TripWalletId,
            WalletTransactionType.ContributionCredit,
            TransactionDirection.Credit,
            request.Amount,
            contribution.Currency,
            callerId,
            contribution.UserId,
            FundContributionId: contribution.Id,
            PaymentId: contribution.PaymentId,
            OccurredAt: request.ReceivedAt,
            MetadataJson: metadata), ct);

        contribution.WalletTransactionId = walletTransaction.Id;
        await _dbContext.SaveChangesAsync(ct);

        return Ok(new FundContributionResponse(
            contribution.Id,
            contribution.UserId,
            contribution.ExpectedAmount,
            contribution.Amount,
            contribution.Currency,
            contribution.Status.ToString()));
    }

    private static List<(Guid UserId, decimal Amount)> Allocate(
        decimal targetAmount,
        FundAllocationType allocationType,
        IReadOnlyList<FundRequestParticipantRequest> participants)
    {
        return allocationType switch
        {
            FundAllocationType.Equal => AllocateEqual(targetAmount, participants),
            FundAllocationType.Fixed => AllocateFixed(targetAmount, participants),
            FundAllocationType.Percent => AllocatePercent(targetAmount, participants),
            FundAllocationType.Weight => AllocateWeight(targetAmount, participants),
            _ => throw new DomainException("Loại phân bổ quỹ này không được hỗ trợ.", "UNSUPPORTED_FUND_ALLOCATION")
        };
    }

    private static List<(Guid UserId, decimal Amount)> AllocateEqual(decimal targetAmount, IReadOnlyList<FundRequestParticipantRequest> participants)
    {
        var amount = Math.Round(targetAmount / participants.Count, 0, MidpointRounding.AwayFromZero);
        var result = participants.Select(p => (p.UserId, Amount: amount)).ToList();
        return DistributeDelta(targetAmount, result);
    }

    private static List<(Guid UserId, decimal Amount)> AllocateFixed(decimal targetAmount, IReadOnlyList<FundRequestParticipantRequest> participants)
    {
        var result = participants.Select(p => (p.UserId, Amount: p.Amount ?? 0m)).ToList();
        if (Math.Abs(result.Sum(p => p.Amount) - targetAmount) > 0.0001m)
        {
            throw new DomainException("Tổng phân bổ cố định phải bằng số tiền mục tiêu.", "FUND_FIXED_TOTAL_MISMATCH");
        }

        return result;
    }

    private static List<(Guid UserId, decimal Amount)> AllocatePercent(decimal targetAmount, IReadOnlyList<FundRequestParticipantRequest> participants)
    {
        var totalPercent = participants.Sum(p => p.Percentage ?? 0m);
        if (Math.Abs(totalPercent - 100m) > 0.0001m)
        {
            throw new DomainException("Tổng phần trăm phân bổ quỹ phải bằng 100.", "FUND_PERCENT_TOTAL_MISMATCH");
        }

        var result = participants
            .Select(p => (p.UserId, Amount: Math.Round(targetAmount * (p.Percentage ?? 0m) / 100m, 0, MidpointRounding.AwayFromZero)))
            .ToList();
        return DistributeDelta(targetAmount, result);
    }

    private static List<(Guid UserId, decimal Amount)> AllocateWeight(decimal targetAmount, IReadOnlyList<FundRequestParticipantRequest> participants)
    {
        var totalWeight = participants.Sum(p => p.Weight ?? 0m);
        if (totalWeight <= 0)
        {
            throw new DomainException("Trọng số phân bổ quỹ phải lớn hơn 0.", "FUND_WEIGHT_INVALID");
        }

        var result = participants
            .Select(p => (p.UserId, Amount: Math.Round(targetAmount * (p.Weight ?? 0m) / totalWeight, 0, MidpointRounding.AwayFromZero)))
            .ToList();
        return DistributeDelta(targetAmount, result);
    }

    private static List<(Guid UserId, decimal Amount)> DistributeDelta(decimal targetAmount, List<(Guid UserId, decimal Amount)> amounts)
    {
        var delta = targetAmount - amounts.Sum(a => a.Amount);
        if (delta != 0 && amounts.Count > 0)
        {
            var first = amounts[0];
            amounts[0] = (first.UserId, first.Amount + delta);
        }

        return amounts;
    }
}

public sealed record CreateFundRequestRequest(
    string Title,
    decimal TargetAmount,
    string? Currency,
    FundAllocationType AllocationType,
    IReadOnlyList<FundRequestParticipantRequest> Participants,
    DateTime? DueAt,
    string? Note);

public sealed record FundRequestParticipantRequest(Guid UserId, decimal? Amount, decimal? Percentage, decimal? Weight);

public sealed record ConfirmFundContributionRequest(decimal Amount, DateTime? ReceivedAt, string? PaymentReference, Guid? ProofFileId);

public sealed record FundRequestResponse(
    Guid FundRequestId,
    Guid WalletId,
    string Title,
    decimal TargetAmount,
    string Currency,
    string AllocationType,
    DateTime? DueAt,
    IReadOnlyList<FundContributionResponse> Contributions);

public sealed record FundContributionResponse(
    Guid FundContributionId,
    Guid UserId,
    decimal ExpectedAmount,
    decimal Amount,
    string Currency,
    string Status);
