using BuildingBlocks.CQRS;

namespace Trip.API.Features.JoinTrip;

public sealed record JoinTripCommand(
    string InviteCode,
    Guid UserId,
    int UserTier,
    string? NickName) : ICommand<JoinTripResult>;

public sealed record JoinTripResult(
    Guid TripId,
    string TripName,
    int MemberCount);
