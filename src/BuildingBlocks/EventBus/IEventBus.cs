namespace BuildingBlocks.EventBus;

/// <summary>
/// Abstraction for publishing integration events. Allows swapping
/// in-process dispatch for a real message broker (RabbitMQ, Kafka, etc.)
/// without changing consuming code.
/// </summary>
public interface IEventBus
{
    Task PublishAsync(IIntegrationEvent integrationEvent, CancellationToken cancellationToken = default);
    Task PublishAsync(IEnumerable<IIntegrationEvent> integrationEvents, CancellationToken cancellationToken = default);
}
