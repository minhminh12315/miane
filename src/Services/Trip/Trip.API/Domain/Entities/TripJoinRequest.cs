using BuildingBlocks.Domain;
using Trip.API.Domain.Enums;

namespace Trip.API.Domain.Entities;

public class TripJoinRequest : BaseEntity
{
    public Guid TripId { get; set; }
    public Guid UserId { get; set; }
    public string? NickName { get; set; }
    public string? Message { get; set; }
    public TripJoinRequestStatus Status { get; set; } = TripJoinRequestStatus.Pending;
    public Guid? RespondedByUserId { get; set; }
    public DateTime? RespondedAt { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
