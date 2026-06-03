using MediatR;

namespace BuildingBlocks.EventBus;

/// <summary>
/// Marker interface for integration events that cross service boundaries.
/// </summary>
public interface IIntegrationEvent : INotification
{
    Guid EventId { get; }
    DateTime OccurredOn { get; }
    string EventType { get; }
}
