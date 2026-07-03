using BuildingBlocks.CQRS;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Enums;

namespace Trip.API.Features.GetUserTrips;

public sealed record GetUserTripsQuery(Guid UserId) : IQuery<List<UserTripResponse>>;

public sealed record UserTripResponse(
    Guid Id,
    string Name,
    string? Description,
    string InviteCode,
    string BaseCurrency,
    TripStatus Status,
    int MemberCount,
    MemberRole UserRole,
    string? UserRoleName,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? CoverImageUrl,
    string ShareUrl,
    DateTime CreatedAt);

public sealed class GetUserTripsHandler : IQueryHandler<GetUserTripsQuery, List<UserTripResponse>>
{
    private readonly ITripRepository _tripRepository;

    public GetUserTripsHandler(ITripRepository tripRepository)
    {
        _tripRepository = tripRepository;
    }

    public async Task<List<UserTripResponse>> Handle(GetUserTripsQuery request, CancellationToken cancellationToken)
    {
        var trips = await _tripRepository.GetTripsByUserIdAsync(request.UserId, cancellationToken);

        return trips.Select(t =>
        {
            var userMember = t.Members.FirstOrDefault(m => m.UserId == request.UserId);
            return new UserTripResponse(
                t.Id,
                t.Name,
                t.Description,
                t.InviteCode,
                t.BaseCurrency,
                t.Status,
                t.Members.Count,
                userMember?.Role ?? MemberRole.Member,
                userMember?.CustomRole?.RoleName,
                t.DestinationCity,
                t.DestinationCountry,
                t.Latitude,
                t.Longitude,
                t.StartDate,
                t.EndDate,
                t.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl ?? t.CoverImageUrl,
                t.ShareLinks.FirstOrDefault(s => s.IsActive)?.Url ?? $"https://miane.app/trip/{t.InviteCode}",
                t.CreatedAt);
        }).ToList();
    }
}
