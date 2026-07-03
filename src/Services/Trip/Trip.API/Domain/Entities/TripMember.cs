using BuildingBlocks.Domain;
using Trip.API.Domain.Enums;

namespace Trip.API.Domain.Entities;

/// <summary>
/// Represents a member's participation in a trip.
/// </summary>
public class TripMember : BaseEntity
{
    public Guid TripId { get; set; }
    public Guid UserId { get; set; }
    public Guid? RoleId { get; set; }
    public MemberRole Role { get; set; } = MemberRole.Member;
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public string? NickName { get; set; }

    /// <summary>
    /// Cached tier value at the time of joining, used for display purposes.
    /// Actual tier enforcement reads from the JWT header.
    /// </summary>
    public int UserTier { get; set; }

    // Navigation
    public TripEntity Trip { get; set; } = null!;
    public TripRole? CustomRole { get; set; }
}
