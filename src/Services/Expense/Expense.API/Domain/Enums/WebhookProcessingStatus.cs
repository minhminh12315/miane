namespace Expense.API.Domain.Enums;

public enum WebhookProcessingStatus
{
    Received = 0,
    Processed = 1,
    Ignored = 2,
    Failed = 3
}
