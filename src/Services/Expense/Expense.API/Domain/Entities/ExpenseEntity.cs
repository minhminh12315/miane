using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

/// <summary>
/// Aggregate root representing an expense within a trip.
/// </summary>
public class ExpenseEntity : AggregateRoot
{
    public Guid TripId { get; set; }
    public string? Title { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? Category { get; set; }

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
    public ExpenseStatus Status { get; set; } = ExpenseStatus.Posted;
    public DateTime? PaidAt { get; set; }
    public Guid? ReceiptFileId { get; set; }
    public Guid? ParentExpenseId { get; set; }
    public decimal RoundingDelta { get; set; }

    /// <summary>
    /// If true, this expense was paid from the trip's shared pool/fund.
    /// </summary>
    public bool IsPaidFromPool { get; set; }

    // Navigation
    private readonly List<ExpenseSplit> _splits = new();
    private readonly List<ExpenseItem> _items = new();
    private readonly List<ExpenseParticipant> _participants = new();
    private readonly List<ExpensePaymentSource> _paymentSources = new();

    public IReadOnlyCollection<ExpenseSplit> Splits => _splits.AsReadOnly();
    public IReadOnlyCollection<ExpenseItem> Items => _items.AsReadOnly();
    public IReadOnlyCollection<ExpenseParticipant> Participants => _participants.AsReadOnly();
    public IReadOnlyCollection<ExpensePaymentSource> PaymentSources => _paymentSources.AsReadOnly();

    public void AddSplit(ExpenseSplit split)
    {
        _splits.Add(split);
    }

    public void AddItem(ExpenseItem item)
    {
        _items.Add(item);
    }

    public void AddParticipant(ExpenseParticipant participant)
    {
        _participants.Add(participant);
    }

    public void AddPaymentSource(ExpensePaymentSource paymentSource)
    {
        _paymentSources.Add(paymentSource);
    }
}
