namespace BuildingBlocks.EventBus;

/// <summary>
/// Base record for integration events providing common metadata fields.
/// Uses records for immutability and value-based equality.
/// </summary>
public abstract record IntegrationEvent : IIntegrationEvent
{
    public Guid EventId { get; init; } = Guid.NewGuid();
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
    public string EventType => GetType().Name;
}
