using BuildingBlocks.CQRS;
using BuildingBlocks.Exceptions;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Enums;

namespace Trip.API.Features.GetTrip;

public sealed record GetTripQuery(Guid TripId, Guid UserId) : IQuery<TripDetailResponse>;

public sealed record TripDetailResponse(
    Guid Id,
    string Name,
    string? Description,
    string InviteCode,
    string BaseCurrency,
    TripStatus Status,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? CoverImageUrl,
    string ShareUrl,
    DateTime CreatedAt,
    List<TripMemberResponse> Members);

public sealed record TripMemberResponse(
    Guid UserId,
    MemberRole Role,
    string? RoleName,
    string? NickName,
    int UserTier,
    DateTime JoinedAt);

public sealed class GetTripHandler : IQueryHandler<GetTripQuery, TripDetailResponse>
{
    private readonly ITripRepository _tripRepository;

    public GetTripHandler(ITripRepository tripRepository)
    {
        _tripRepository = tripRepository;
    }

    public async Task<TripDetailResponse> Handle(GetTripQuery request, CancellationToken cancellationToken)
    {
        var trip = await _tripRepository.GetWithMembersAsync(request.TripId, cancellationToken)
            ?? throw new NotFoundException("Trip", request.TripId);

        // Verify user is a member
        if (!trip.Members.Any(m => m.UserId == request.UserId))
        {
            throw new ForbiddenAccessException("You are not a member of this trip.");
        }

        return new TripDetailResponse(
            trip.Id,
            trip.Name,
            trip.Description,
            trip.InviteCode,
            trip.BaseCurrency,
            trip.Status,
            trip.DestinationCity,
            trip.DestinationCountry,
            trip.Latitude,
            trip.Longitude,
            trip.StartDate,
            trip.EndDate,
            trip.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl ?? trip.CoverImageUrl,
            trip.ShareLinks.FirstOrDefault(s => s.IsActive)?.Url ?? $"https://miane.app/trip/{trip.InviteCode}",
            trip.CreatedAt,
            trip.Members.Select(m => new TripMemberResponse(
                m.UserId,
                m.Role,
                m.CustomRole?.RoleName,
                m.NickName,
                m.UserTier,
                m.JoinedAt)).ToList());
    }
}
