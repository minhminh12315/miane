using BuildingBlocks.CQRS;
using BuildingBlocks.Exceptions;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Enums;

namespace Trip.API.Features.DeleteTrip;

public sealed record DeleteTripCommand(
    Guid TripId,
    Guid UserId) : ICommand;

public sealed class DeleteTripHandler : ICommandHandler<DeleteTripCommand>
{
    private readonly ITripRepository _tripRepository;

    public DeleteTripHandler(ITripRepository tripRepository)
    {
        _tripRepository = tripRepository;
    }

    public async Task<MediatR.Unit> Handle(DeleteTripCommand request, CancellationToken cancellationToken)
    {
        var trip = await _tripRepository.GetWithMembersAsync(request.TripId, cancellationToken)
            ?? throw new NotFoundException("Trip", request.TripId);

        var member = trip.Members.FirstOrDefault(m => m.UserId == request.UserId);
        if (member is null || member.Role != MemberRole.Owner)
        {
            throw new ForbiddenAccessException("Chỉ chủ chuyến đi mới có thể xóa chuyến đi này.");
        }

        await _tripRepository.DeleteAsync(trip, cancellationToken);
        await _tripRepository.SaveChangesAsync(cancellationToken);

        return MediatR.Unit.Value;
    }
}
