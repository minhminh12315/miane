using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;
using Trip.API.IntegrationEvents;

namespace Trip.API.Features.CreateTrip;

public sealed class CreateTripHandler : ICommandHandler<CreateTripCommand, CreateTripResult>
{
    private readonly ITripRepository _tripRepository;
    private readonly IEventBus _eventBus;

    public CreateTripHandler(ITripRepository tripRepository, IEventBus eventBus)
    {
        _tripRepository = tripRepository;
        _eventBus = eventBus;
    }

    public async Task<CreateTripResult> Handle(CreateTripCommand request, CancellationToken cancellationToken)
    {
        var trip = new TripEntity
        {
            Name = request.Name,
            Description = request.Description,
            BaseCurrency = request.BaseCurrency.ToUpperInvariant(),
            CreatedByUserId = request.UserId,
            InviteCode = TripEntity.GenerateInviteCode(),
            Status = TripStatus.Active
        };

        // Creator is automatically the owner
        var ownerMember = new TripMember
        {
            TripId = trip.Id,
            UserId = request.UserId,
            Role = MemberRole.Owner,
            UserTier = request.UserTier,
            JoinedAt = DateTime.UtcNow
        };

        trip.AddMember(ownerMember);

        await _tripRepository.AddAsync(trip, cancellationToken);
        await _tripRepository.SaveChangesAsync(cancellationToken);

        await _eventBus.PublishAsync(new TripCreatedEvent
        {
            TripId = trip.Id,
            TripName = trip.Name,
            CreatedByUserId = request.UserId,
            InviteCode = trip.InviteCode
        }, cancellationToken);

        return new CreateTripResult(trip.Id, trip.InviteCode);
    }
}
