using BuildingBlocks.EventBus;

namespace Expense.API.IntegrationEvents;

public sealed record ExpenseCreatedEvent : IntegrationEvent
{
    public Guid ExpenseId { get; init; }
    public Guid TripId { get; init; }
    public string Description { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public string Currency { get; init; } = string.Empty;
    public Guid PaidByUserId { get; init; }
}

public sealed record DebtSettledEvent : IntegrationEvent
{
    public Guid DebtRecordId { get; init; }
    public Guid TripId { get; init; }
    public Guid FromUserId { get; init; }
    public Guid ToUserId { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; } = string.Empty;
}
