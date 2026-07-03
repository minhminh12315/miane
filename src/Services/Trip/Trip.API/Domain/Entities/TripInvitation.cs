using BuildingBlocks.Domain;
using Trip.API.Domain.Enums;

namespace Trip.API.Domain.Entities;

public class TripInvitation : BaseEntity
{
    public Guid TripId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string ShareUrl { get; set; } = string.Empty;
    public TripInvitationMethod Method { get; set; } = TripInvitationMethod.Code;
    public TripInvitationStatus Status { get; set; } = TripInvitationStatus.Active;
    public Guid CreatedByUserId { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
