using BuildingBlocks.CQRS;

namespace Trip.API.Features.CreateTrip;

public sealed record CreateTripCommand(
    string Name,
    string? Description,
    string BaseCurrency,
    string? Destination,
    string? DestinationCity,
    string? DestinationCountry,
    double? Latitude,
    double? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? CoverImageUrl,
    Guid UserId,
    int UserTier) : ICommand<CreateTripResult>;

public sealed record CreateTripResult(
    Guid TripId,
    string InviteCode,
    string ShareUrl);
