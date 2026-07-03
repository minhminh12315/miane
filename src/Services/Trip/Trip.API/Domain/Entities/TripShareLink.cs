using BuildingBlocks.Domain;
using Trip.API.Domain.Enums;

namespace Trip.API.Domain.Entities;

public class TripShareLink : BaseEntity
{
    public Guid TripId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public TripShareLinkType Type { get; set; } = TripShareLinkType.Invitation;
    public Guid CreatedByUserId { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public bool IsActive { get; set; } = true;

    public TripEntity Trip { get; set; } = null!;
}
