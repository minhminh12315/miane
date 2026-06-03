using BuildingBlocks.CQRS;
using BuildingBlocks.Exceptions;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Enums;

namespace Trip.API.Features.UpdateTrip;

public sealed record UpdateTripCommand(
    Guid TripId,
    Guid UserId,
    string? Name,
    string? Description,
    TripStatus? Status) : ICommand;

public sealed class UpdateTripHandler : ICommandHandler<UpdateTripCommand>
{
    private readonly ITripRepository _tripRepository;

    public UpdateTripHandler(ITripRepository tripRepository)
    {
        _tripRepository = tripRepository;
    }

    public async Task<MediatR.Unit> Handle(UpdateTripCommand request, CancellationToken cancellationToken)
    {
        var trip = await _tripRepository.GetWithMembersAsync(request.TripId, cancellationToken)
            ?? throw new NotFoundException("Trip", request.TripId);

        // Only Owner or Admin can update
        var member = trip.Members.FirstOrDefault(m => m.UserId == request.UserId);
        if (member is null || (member.Role != MemberRole.Owner && member.Role != MemberRole.Admin))
        {
            throw new ForbiddenAccessException("Only the trip owner or admin can update trip details.");
        }

        if (!string.IsNullOrWhiteSpace(request.Name))
            trip.Name = request.Name;

        if (request.Description is not null)
            trip.Description = request.Description;

        if (request.Status.HasValue)
            trip.Status = request.Status.Value;

        await _tripRepository.UpdateAsync(trip, cancellationToken);
        await _tripRepository.SaveChangesAsync(cancellationToken);

        return MediatR.Unit.Value;
    }
}
