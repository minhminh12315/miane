using BuildingBlocks.CQRS;
using BuildingBlocks.Exceptions;
using Trip.API.Data;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Enums;

namespace Trip.API.Features.LeaveTrip;

public sealed record LeaveTripCommand(
    Guid TripId,
    Guid UserId) : ICommand;

public sealed class LeaveTripHandler : ICommandHandler<LeaveTripCommand>
{
    private readonly ITripRepository _tripRepository;
    private readonly TripDbContext _dbContext;

    public LeaveTripHandler(ITripRepository tripRepository, TripDbContext dbContext)
    {
        _tripRepository = tripRepository;
        _dbContext = dbContext;
    }

    public async Task<MediatR.Unit> Handle(LeaveTripCommand request, CancellationToken cancellationToken)
    {
        var member = await _tripRepository.GetTripMemberAsync(request.TripId, request.UserId, cancellationToken)
            ?? throw new NotFoundException("TripMember", request.UserId);

        if (member.Role == MemberRole.Owner)
        {
            throw new DomainException(
                "Chủ chuyến đi không thể rời chuyến đi. Vui lòng chuyển quyền sở hữu cho thành viên khác trước.",
                "OWNER_CANNOT_LEAVE");
        }

        _dbContext.TripMembers.Remove(member);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return MediatR.Unit.Value;
    }
}
