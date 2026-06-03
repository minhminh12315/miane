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
                t.CreatedAt);
        }).ToList();
    }
}
