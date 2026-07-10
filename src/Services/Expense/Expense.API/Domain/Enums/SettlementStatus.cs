namespace Expense.API.Domain.Enums;

public enum SettlementStatus
{
    Open = 0,
    PaymentPending = 1,
    Paid = 2,
    PartiallyPaid = 3,
    Cancelled = 4,
    Disputed = 5,
    Superseded = 6
}
