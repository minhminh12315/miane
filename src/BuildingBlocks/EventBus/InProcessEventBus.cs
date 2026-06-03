using MediatR;
using Microsoft.Extensions.Logging;

namespace BuildingBlocks.EventBus;

/// <summary>
/// In-process event bus implementation using MediatR's Publish (notification pattern).
/// Suitable for monolithic deployments or when all services share a single process.
/// For true microservices, swap this with a RabbitMQ/Kafka-backed implementation.
/// </summary>
public sealed class InProcessEventBus : IEventBus
{
    private readonly IMediator _mediator;
    private readonly ILogger<InProcessEventBus> _logger;

    public InProcessEventBus(IMediator mediator, ILogger<InProcessEventBus> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    public async Task PublishAsync(IIntegrationEvent integrationEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "[EventBus] Publishing {EventType} (EventId: {EventId})",
            integrationEvent.EventType, integrationEvent.EventId);

        await _mediator.Publish(integrationEvent, cancellationToken);
    }

    public async Task PublishAsync(IEnumerable<IIntegrationEvent> integrationEvents, CancellationToken cancellationToken = default)
    {
        foreach (var integrationEvent in integrationEvents)
        {
            await PublishAsync(integrationEvent, cancellationToken);
        }
    }
}
