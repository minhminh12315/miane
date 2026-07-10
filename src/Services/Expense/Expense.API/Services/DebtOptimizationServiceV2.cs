using Expense.API.Data;
using Expense.API.Domain.Entities;
using Expense.API.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Expense.API.Services;

public sealed record OptimizedDebt(Guid FromUserId, Guid ToUserId, decimal Amount, string Currency);

public sealed class DebtOptimizationServiceV2
{
    private const decimal Epsilon = 0.01m;

    private readonly ExpenseDbContext _dbContext;
    private readonly ILogger<DebtOptimizationServiceV2> _logger;

    public DebtOptimizationServiceV2(ExpenseDbContext dbContext, ILogger<DebtOptimizationServiceV2> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<IReadOnlyList<Debt>> RecalculateAsync(
        Guid tripId,
        string currency,
        CancellationToken cancellationToken = default)
    {
        var calculationRunId = Guid.NewGuid();
        var netBalances = await BuildNetBalancesAsync(tripId, cancellationToken);
        var optimized = Simplify(netBalances, currency);

        var openDebts = await _dbContext.Debts
            .Where(d => d.TripId == tripId && d.Status == DebtStatus.Open)
            .ToListAsync(cancellationToken);

        foreach (var debt in openDebts)
        {
            debt.Status = DebtStatus.Superseded;
        }

        var newDebts = optimized
            .Select(d => new Debt
            {
                TripId = tripId,
                FromUserId = d.FromUserId,
                ToUserId = d.ToUserId,
                Amount = d.Amount,
                Currency = d.Currency,
                Status = DebtStatus.Open,
                CalculationRunId = calculationRunId
            })
            .ToList();

        if (newDebts.Count > 0)
        {
            await _dbContext.Debts.AddRangeAsync(newDebts, cancellationToken);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        _logger.LogInformation(
            "[DebtOptimizationV2] TripId: {TripId} generated {DebtCount} open debts in run {RunId}",
            tripId,
            newDebts.Count,
            calculationRunId);

        return newDebts;
    }

    public IReadOnlyList<OptimizedDebt> Simplify(
        IReadOnlyDictionary<Guid, decimal> netBalances,
        string currency)
    {
        var creditors = netBalances
            .Where(kv => kv.Value > Epsilon)
            .OrderByDescending(kv => kv.Value)
            .Select(kv => new BalanceCursor(kv.Key, kv.Value))
            .ToList();

        var debtors = netBalances
            .Where(kv => kv.Value < -Epsilon)
            .OrderBy(kv => kv.Value)
            .Select(kv => new BalanceCursor(kv.Key, Math.Abs(kv.Value)))
            .ToList();

        var optimized = new List<OptimizedDebt>();
        var creditorIndex = 0;
        var debtorIndex = 0;

        while (creditorIndex < creditors.Count && debtorIndex < debtors.Count)
        {
            var amount = Math.Min(creditors[creditorIndex].Amount, debtors[debtorIndex].Amount);

            if (amount > Epsilon)
            {
                optimized.Add(new OptimizedDebt(
                    debtors[debtorIndex].UserId,
                    creditors[creditorIndex].UserId,
                    Math.Round(amount, 4),
                    currency.ToUpperInvariant()));
            }

            creditors[creditorIndex] = creditors[creditorIndex] with { Amount = creditors[creditorIndex].Amount - amount };
            debtors[debtorIndex] = debtors[debtorIndex] with { Amount = debtors[debtorIndex].Amount - amount };

            if (creditors[creditorIndex].Amount <= Epsilon)
            {
                creditorIndex++;
            }

            if (debtors[debtorIndex].Amount <= Epsilon)
            {
                debtorIndex++;
            }
        }

        return optimized;
    }

    private async Task<Dictionary<Guid, decimal>> BuildNetBalancesAsync(
        Guid tripId,
        CancellationToken cancellationToken)
    {
        var expenses = await _dbContext.Expenses
            .Include(e => e.Splits)
            .Include(e => e.Participants)
            .Include(e => e.PaymentSources)
            .Where(e => e.TripId == tripId && e.Status != ExpenseStatus.Voided)
            .ToListAsync(cancellationToken);

        var netBalances = new Dictionary<Guid, decimal>();

        foreach (var expense in expenses)
        {
            if (expense.PaymentSources.Count > 0)
            {
                ApplyV2Expense(expense, netBalances);
            }
            else if (!expense.IsPaidFromPool)
            {
                ApplyLegacyExpense(expense, netBalances);
            }
        }

        var paidSettlements = await _dbContext.Settlements
            .Where(s => s.TripId == tripId && (s.Status == SettlementStatus.Paid || s.Status == SettlementStatus.PartiallyPaid))
            .ToListAsync(cancellationToken);

        foreach (var settlement in paidSettlements)
        {
            AddBalance(netBalances, settlement.FromUserId, settlement.PaidAmount);
            AddBalance(netBalances, settlement.ToUserId, -settlement.PaidAmount);
        }

        return netBalances;
    }

    private static void ApplyV2Expense(ExpenseEntity expense, Dictionary<Guid, decimal> netBalances)
    {
        var participants = expense.Participants.Count > 0
            ? expense.Participants.Select(p => new SplitShare(p.UserId, p.ShareAmount)).ToList()
            : expense.Splits.Select(s => new SplitShare(s.UserId, s.Amount)).ToList();

        var advancedTotal = expense.PaymentSources
            .Where(s => s.SourceType == ExpensePaymentSourceType.MemberAdvance || s.SourceType == ExpensePaymentSourceType.ExternalProvider)
            .Sum(s => s.Amount);

        if (advancedTotal <= Epsilon)
        {
            return;
        }

        var shareRatio = expense.ConvertedAmount <= 0 ? 0 : advancedTotal / expense.ConvertedAmount;

        foreach (var source in expense.PaymentSources.Where(s => s.SourceType == ExpensePaymentSourceType.MemberAdvance && s.UserId.HasValue))
        {
            AddBalance(netBalances, source.UserId!.Value, source.Amount);
        }

        foreach (var participant in participants)
        {
            AddBalance(netBalances, participant.UserId, -participant.Amount * shareRatio);
        }
    }

    private static void ApplyLegacyExpense(ExpenseEntity expense, Dictionary<Guid, decimal> netBalances)
    {
        AddBalance(netBalances, expense.PaidByUserId, expense.Splits.Sum(s => s.Amount));

        foreach (var split in expense.Splits)
        {
            AddBalance(netBalances, split.UserId, -split.Amount);
        }
    }

    private static void AddBalance(Dictionary<Guid, decimal> balances, Guid userId, decimal amount)
    {
        if (!balances.ContainsKey(userId))
        {
            balances[userId] = 0m;
        }

        balances[userId] += amount;
    }

    private sealed record BalanceCursor(Guid UserId, decimal Amount);
}
