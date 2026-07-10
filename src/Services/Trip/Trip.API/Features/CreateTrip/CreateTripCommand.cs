using BuildingBlocks.CQRS;

namespace Trip.API.Features.CreateTrip;

public sealed record CreateTripCommand(
    string Name,
    string? Description,
    string BaseCurrency,
    string? Destination,
    string? PlaceId,
    string? FormattedAddress,
    string? DestinationCity,
    string? DestinationProvince,
    string? DestinationCountry,
    IReadOnlyCollection<string>? PlaceTypes,
    string? PlaceMetadataJson,
    double? Latitude,
    double? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? CoverImageUrl,
    string? CoverImagePrompt,
    string? CoverImageLandmark,
    Guid UserId,
    int UserTier) : ICommand<CreateTripResult>;

public sealed record CreateTripResult(
    Guid TripId,
    string InviteCode,
    string ShareUrl);
