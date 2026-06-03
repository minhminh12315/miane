using Expense.API.Data;
using Expense.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Expense.API.Services;

/// <summary>
/// Graph-based debt simplification algorithm that minimizes the number of
/// peer-to-peer transactions needed to settle all debts within a trip.
///
/// Algorithm:
/// 1. Calculate net balance for each user (total_received - total_owed)
/// 2. Separate into creditors (positive) and debtors (negative)
/// 3. Sort both by absolute value descending
/// 4. Greedily match max creditor to max debtor
/// 5. Persist simplified DebtRecord entries
/// </summary>
public sealed class DebtSimplificationService
{
    private readonly ExpenseDbContext _dbContext;
    private readonly ILogger<DebtSimplificationService> _logger;

    public DebtSimplificationService(ExpenseDbContext dbContext, ILogger<DebtSimplificationService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    /// <summary>
    /// Recalculates and simplifies all debts for a given trip.
    /// Replaces existing unsettled debt records with new simplified ones.
    /// </summary>
    public async Task SimplifyDebtsAsync(Guid tripId, string baseCurrency, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("[DebtSimplification] Running for TripId: {TripId}", tripId);

        // Step 1: Calculate net balances from all non-pool expenses
        var expenses = await _dbContext.Expenses
            .Include(e => e.Splits)
            .Where(e => e.TripId == tripId && !e.IsPaidFromPool)
            .ToListAsync(cancellationToken);

        var netBalances = new Dictionary<Guid, decimal>();

        foreach (var expense in expenses)
        {
            // The payer is owed money (positive balance)
            var payerId = expense.PaidByUserId;
            if (!netBalances.ContainsKey(payerId))
                netBalances[payerId] = 0m;

            foreach (var split in expense.Splits)
            {
                if (!netBalances.ContainsKey(split.UserId))
                    netBalances[split.UserId] = 0m;

                if (split.UserId != payerId)
                {
                    // Payer gets credited, split user gets debited
                    netBalances[payerId] += split.Amount;
                    netBalances[split.UserId] -= split.Amount;
                }
            }
        }

        // Step 2: Account for already-settled debts
        var settledDebts = await _dbContext.DebtRecords
            .Where(d => d.TripId == tripId && d.IsSettled)
            .ToListAsync(cancellationToken);

        foreach (var settled in settledDebts)
        {
            if (!netBalances.ContainsKey(settled.FromUserId))
                netBalances[settled.FromUserId] = 0m;
            if (!netBalances.ContainsKey(settled.ToUserId))
                netBalances[settled.ToUserId] = 0m;

            // Settlement reduces the from-user's debt and the to-user's credit
            netBalances[settled.FromUserId] += settled.Amount;
            netBalances[settled.ToUserId] -= settled.Amount;
        }

        // Step 3: Remove existing unsettled debt records
        var unsettledDebts = await _dbContext.DebtRecords
            .Where(d => d.TripId == tripId && !d.IsSettled)
            .ToListAsync(cancellationToken);

        _dbContext.DebtRecords.RemoveRange(unsettledDebts);

        // Step 4: Separate into creditors and debtors
        var creditors = netBalances
            .Where(kv => kv.Value > 0.01m)
            .OrderByDescending(kv => kv.Value)
            .Select(kv => new { UserId = kv.Key, Balance = kv.Value })
            .ToList();

        var debtors = netBalances
            .Where(kv => kv.Value < -0.01m)
            .OrderBy(kv => kv.Value) // Most negative first
            .Select(kv => new { UserId = kv.Key, Balance = Math.Abs(kv.Value) })
            .ToList();

        // Step 5: Greedy matching — minimize number of transactions
        var simplifiedDebts = new List<DebtRecord>();
        int ci = 0, di = 0;
        var creditorBalances = creditors.Select(c => c.Balance).ToArray();
        var debtorBalances = debtors.Select(d => d.Balance).ToArray();

        while (ci < creditors.Count && di < debtors.Count)
        {
            var amount = Math.Min(creditorBalances[ci], debtorBalances[di]);

            if (amount > 0.01m) // Skip trivially small amounts
            {
                simplifiedDebts.Add(new DebtRecord
                {
                    TripId = tripId,
                    FromUserId = debtors[di].UserId,
                    ToUserId = creditors[ci].UserId,
                    Amount = Math.Round(amount, 4),
                    Currency = baseCurrency,
                    IsSettled = false
                });
            }

            creditorBalances[ci] -= amount;
            debtorBalances[di] -= amount;

            if (creditorBalances[ci] < 0.01m) ci++;
            if (debtorBalances[di] < 0.01m) di++;
        }

        if (simplifiedDebts.Count > 0)
        {
            await _dbContext.DebtRecords.AddRangeAsync(simplifiedDebts, cancellationToken);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "[DebtSimplification] TripId: {TripId} — Simplified {OriginalCount} balances into {SimplifiedCount} transactions",
            tripId, netBalances.Count, simplifiedDebts.Count);
    }
}
