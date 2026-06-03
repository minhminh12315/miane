using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

/// <summary>
/// Aggregate root representing an expense within a trip.
/// </summary>
public class ExpenseEntity : AggregateRoot
{
    public Guid TripId { get; set; }
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Original amount in the expense's currency.
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// ISO 4217 currency code (e.g., USD, VND, EUR).
    /// </summary>
    public string Currency { get; set; } = "VND";

    /// <summary>
    /// Amount converted to the trip's base currency using the exchange rate at creation time.
    /// </summary>
    public decimal ConvertedAmount { get; set; }

    /// <summary>
    /// The exchange rate used for conversion (1 unit of Currency = X units of BaseCurrency).
    /// </summary>
    public decimal ExchangeRate { get; set; } = 1m;

    public Guid PaidByUserId { get; set; }
    public SplitType SplitType { get; set; } = SplitType.Equal;

    /// <summary>
    /// If true, this expense was paid from the trip's shared pool/fund.
    /// </summary>
    public bool IsPaidFromPool { get; set; }

    // Navigation
    private readonly List<ExpenseSplit> _splits = new();
    public IReadOnlyCollection<ExpenseSplit> Splits => _splits.AsReadOnly();

    public void AddSplit(ExpenseSplit split)
    {
        _splits.Add(split);
    }
}
