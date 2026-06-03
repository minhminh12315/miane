using BuildingBlocks.Domain;
using Trip.API.Domain.Enums;

namespace Trip.API.Domain.Entities;

/// <summary>
/// Aggregate root representing a group trip.
/// </summary>
public class TripEntity : AggregateRoot
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>
    /// Unique 8-character alphanumeric invite code for joining the trip.
    /// </summary>
    public string InviteCode { get; set; } = string.Empty;

    public string BaseCurrency { get; set; } = "VND";
    public Guid CreatedByUserId { get; set; }
    public TripStatus Status { get; set; } = TripStatus.Active;

    // Navigation
    private readonly List<TripMember> _members = new();
    public IReadOnlyCollection<TripMember> Members => _members.AsReadOnly();

    public void AddMember(TripMember member)
    {
        _members.Add(member);
    }

    public static string GenerateInviteCode()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        var random = Random.Shared;
        return new string(Enumerable.Range(0, 8).Select(_ => chars[random.Next(chars.Length)]).ToArray());
    }
}
