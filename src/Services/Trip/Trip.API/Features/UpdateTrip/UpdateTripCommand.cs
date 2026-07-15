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
    TripStatus? Status,
    DateTime? StartDate = null,
    DateTime? EndDate = null) : ICommand;

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
            ?? throw new NotFoundException("chuyến đi", request.TripId);

        // Only Owner or Admin can update
        var member = trip.Members.FirstOrDefault(m => m.UserId == request.UserId);
        if (member is null || (member.Role != MemberRole.Owner && member.Role != MemberRole.Admin))
        {
            throw new ForbiddenAccessException("Chỉ chủ chuyến đi hoặc quản trị viên mới có thể cập nhật thông tin chuyến đi.");
        }

        if (!string.IsNullOrWhiteSpace(request.Name))
            trip.Name = request.Name;

        if (request.Description is not null)
            trip.Description = request.Description;

        if (request.Status.HasValue)
            trip.Status = request.Status.Value;

        if (request.StartDate.HasValue)
            trip.StartDate = request.StartDate.Value;

        if (request.EndDate.HasValue)
            trip.EndDate = request.EndDate.Value;

        if (trip.StartDate.HasValue && trip.EndDate.HasValue &&
            trip.EndDate.Value < trip.StartDate.Value)
        {
            throw new DomainException(
                "Ngày kết thúc chuyến đi không được trước ngày bắt đầu.",
                "INVALID_TRIP_DATE_RANGE");
        }

        await _tripRepository.UpdateAsync(trip, cancellationToken);
        await _tripRepository.SaveChangesAsync(cancellationToken);

        return MediatR.Unit.Value;
    }
}
