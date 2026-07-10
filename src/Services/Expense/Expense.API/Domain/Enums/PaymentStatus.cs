namespace Expense.API.Domain.Enums;

public enum PaymentStatus
{
    Pending = 0,
    Processing = 1,
    Succeeded = 2,
    PartiallySucceeded = 3,
    Failed = 4,
    Expired = 5,
    Disputed = 6,
    Refunded = 7,
    PartiallyRefunded = 8
}
