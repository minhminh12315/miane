using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using BuildingBlocks.Exceptions;
using Trip.API.Data;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Enums;
using Trip.API.IntegrationEvents;

namespace Trip.API.Features.RemoveMember;

public sealed record RemoveMemberCommand(
    Guid TripId,
    Guid TargetUserId,
    Guid RequestingUserId) : ICommand;

public sealed class RemoveMemberHandler : ICommandHandler<RemoveMemberCommand>
{
    private readonly ITripRepository _tripRepository;
    private readonly TripDbContext _dbContext;
    private readonly IEventBus _eventBus;

    public RemoveMemberHandler(ITripRepository tripRepository, TripDbContext dbContext, IEventBus eventBus)
    {
        _tripRepository = tripRepository;
        _dbContext = dbContext;
        _eventBus = eventBus;
    }

    public async Task<MediatR.Unit> Handle(RemoveMemberCommand request, CancellationToken cancellationToken)
    {
        var trip = await _tripRepository.GetWithMembersAsync(request.TripId, cancellationToken)
            ?? throw new NotFoundException("Trip", request.TripId);

        // Only Owner or Admin can remove members
        var requestingMember = trip.Members.FirstOrDefault(m => m.UserId == request.RequestingUserId);
        if (requestingMember is null || (requestingMember.Role != MemberRole.Owner && requestingMember.Role != MemberRole.Admin))
        {
            throw new ForbiddenAccessException("Only the trip owner or admin can remove members.");
        }

        var targetMember = await _tripRepository.GetTripMemberAsync(request.TripId, request.TargetUserId, cancellationToken)
            ?? throw new NotFoundException("TripMember", request.TargetUserId);

        // Cannot remove the owner
        if (targetMember.Role == MemberRole.Owner)
        {
            throw new DomainException("Cannot remove the trip owner.", "CANNOT_REMOVE_OWNER");
        }

        // Admin cannot remove another admin (only owner can)
        if (targetMember.Role == MemberRole.Admin && requestingMember.Role != MemberRole.Owner)
        {
            throw new ForbiddenAccessException("Only the trip owner can remove admins.");
        }

        _dbContext.TripMembers.Remove(targetMember);
        await _dbContext.SaveChangesAsync(cancellationToken);

        await _eventBus.PublishAsync(new MemberRemovedEvent
        {
            TripId = trip.Id,
            TripName = trip.Name,
            RemovedUserId = request.TargetUserId,
            RemovedByUserId = request.RequestingUserId
        }, cancellationToken);

        return MediatR.Unit.Value;
    }
}
