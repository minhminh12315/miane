using BuildingBlocks.EventBus;

namespace Trip.API.IntegrationEvents;

public sealed record TripCreatedEvent : IntegrationEvent
{
    public Guid TripId { get; init; }
    public string TripName { get; init; } = string.Empty;
    public Guid CreatedByUserId { get; init; }
    public string InviteCode { get; init; } = string.Empty;
}

public sealed record MemberJoinedEvent : IntegrationEvent
{
    public Guid TripId { get; init; }
    public string TripName { get; init; } = string.Empty;
    public Guid UserId { get; init; }
    public int MemberCount { get; init; }
}

public sealed record MemberRemovedEvent : IntegrationEvent
{
    public Guid TripId { get; init; }
    public string TripName { get; init; } = string.Empty;
    public Guid RemovedUserId { get; init; }
    public Guid RemovedByUserId { get; init; }
}

public sealed record TripLimitReachedEvent : IntegrationEvent
{
    public Guid TripId { get; init; }
    public string TripName { get; init; } = string.Empty;
    public Guid OwnerUserId { get; init; }
    public int CurrentMemberCount { get; init; }
    public int MaxMembers { get; init; }
}
