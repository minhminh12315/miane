using BuildingBlocks.CQRS;

namespace Trip.API.Features.CreateTrip;

public sealed record CreateTripCommand(
    string Name,
    string? Description,
    string BaseCurrency,
    Guid UserId,
    int UserTier) : ICommand<CreateTripResult>;

public sealed record CreateTripResult(
    Guid TripId,
    string InviteCode);
