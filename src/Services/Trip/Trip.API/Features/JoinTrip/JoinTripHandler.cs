using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using BuildingBlocks.Exceptions;
using System.Text.Json;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;
using Trip.API.IntegrationEvents;

namespace Trip.API.Features.JoinTrip;

public sealed class JoinTripHandler : ICommandHandler<JoinTripCommand, JoinTripResult>
{
    private readonly ITripRepository _tripRepository;
    private readonly IEventBus _eventBus;

    private const int BasicMaxMembers = 7;

    public JoinTripHandler(ITripRepository tripRepository, IEventBus eventBus)
    {
        _tripRepository = tripRepository;
        _eventBus = eventBus;
    }

    public async Task<JoinTripResult> Handle(JoinTripCommand request, CancellationToken cancellationToken)
    {
        var trip = await _tripRepository.GetByInviteCodeAsync(request.InviteCode, cancellationToken)
            ?? throw new NotFoundException("Trip", request.InviteCode);

        if (trip.Status != TripStatus.Active)
        {
            throw new DomainException("Không thể tham gia chuyến đi không còn hoạt động.", "TRIP_NOT_ACTIVE");
        }

        // Check if user is already a member
        if (await _tripRepository.IsUserMemberOfTripAsync(trip.Id, request.UserId, cancellationToken))
        {
            throw new ConflictException("Bạn đã là thành viên của chuyến đi này.");
        }

        // Check member limit based on tier rules
        var currentMemberCount = await _tripRepository.GetMemberCountByTripAsync(trip.Id, cancellationToken);
        EnforceMemberLimit(trip, request, currentMemberCount);

        var member = new TripMember
        {
            TripId = trip.Id,
            UserId = request.UserId,
            Role = MemberRole.Member,
            UserTier = request.UserTier,
            NickName = request.NickName,
            JoinedAt = DateTime.UtcNow
        };

        trip.AddMember(member);
        await _tripRepository.AddMemberAsync(member, cancellationToken);
        await _tripRepository.SaveChangesAsync(cancellationToken);

        var newMemberCount = currentMemberCount + 1;

        await _eventBus.PublishAsync(new MemberJoinedEvent
        {
            TripId = trip.Id,
            TripName = trip.Name,
            UserId = request.UserId,
            MemberCount = newMemberCount
        }, cancellationToken);

        // Notify if the trip has reached the Basic member limit
        if (newMemberCount >= BasicMaxMembers && request.UserTier == 0)
        {
            await _eventBus.PublishAsync(new TripLimitReachedEvent
            {
                TripId = trip.Id,
                TripName = trip.Name,
                OwnerUserId = trip.CreatedByUserId,
                CurrentMemberCount = newMemberCount,
                MaxMembers = BasicMaxMembers
            }, cancellationToken);
        }

        return new JoinTripResult(trip.Id, trip.Name, newMemberCount);
    }

    private static void EnforceMemberLimit(TripEntity trip, JoinTripCommand request, int currentMemberCount)
    {
        // Pro users (tier 1+): unlimited members in all trips
        // We check the trip OWNER's tier, not the joining user's tier
        // But also check if a Trip Pass is active for this specific trip

        // If the joining user is Pro, they can always join (their own membership doesn't affect limits)
        // The limit is enforced based on the trip's context
        if (request.UserTier >= 1)
        {
            return;
        }

        // Rule: Check if ANY member in the trip is Pro, or if a TripPass is active for this trip
        var ownerMember = trip.Members.FirstOrDefault(m => m.Role == MemberRole.Owner);
        if (ownerMember is not null && ownerMember.UserTier >= 1)
        {
            return; // Owner is Pro — unlimited members
        }

        // Check Trip Pass: If the trip creator has a TripPass for this specific trip
        // TripPassTripIds would be checked via the owner's user profile, but since we
        // don't have cross-service access, we rely on a simple trip-level flag approach.
        // For MVP: Pro tier bypasses all limits.

        if (currentMemberCount >= BasicMaxMembers)
        {
            throw new TierLimitExceededException(
                currentTier: 0,
                limitType: "thành viên chuyến đi",
                currentCount: currentMemberCount,
                maxAllowed: BasicMaxMembers);
        }
    }
}
