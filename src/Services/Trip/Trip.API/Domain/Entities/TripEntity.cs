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
    /// Unique alphanumeric invite code for joining the trip.
    /// </summary>
    public string InviteCode { get; set; } = string.Empty;

    public string BaseCurrency { get; set; } = "VND";
    public Guid CreatedByUserId { get; set; }
    public TripStatus Status { get; set; } = TripStatus.Active;
    public string? DestinationCity { get; set; }
    public string? DestinationCountry { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? CoverImageUrl { get; set; }

    // Navigation
    private readonly List<TripMember> _members = new();
    private readonly List<TripRole> _roles = new();
    private readonly List<TripInvitation> _invitations = new();
    private readonly List<TripShareLink> _shareLinks = new();
    private readonly List<TripImage> _images = new();
    private readonly List<TripLocation> _locations = new();

    public IReadOnlyCollection<TripMember> Members => _members.AsReadOnly();
    public IReadOnlyCollection<TripRole> Roles => _roles.AsReadOnly();
    public IReadOnlyCollection<TripInvitation> Invitations => _invitations.AsReadOnly();
    public IReadOnlyCollection<TripShareLink> ShareLinks => _shareLinks.AsReadOnly();
    public IReadOnlyCollection<TripImage> Images => _images.AsReadOnly();
    public IReadOnlyCollection<TripLocation> Locations => _locations.AsReadOnly();

    public void AddMember(TripMember member)
    {
        _members.Add(member);
    }

    public void AddRole(TripRole role)
    {
        _roles.Add(role);
    }

    public void AddInvitation(TripInvitation invitation)
    {
        _invitations.Add(invitation);
    }

    public void AddShareLink(TripShareLink shareLink)
    {
        _shareLinks.Add(shareLink);
    }

    public void AddImage(TripImage image)
    {
        _images.Add(image);
    }

    public void AddLocation(TripLocation location)
    {
        _locations.Add(location);
    }

    public static string GenerateInviteCode(int length = 6)
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        var random = Random.Shared;
        return new string(Enumerable.Range(0, length).Select(_ => chars[random.Next(chars.Length)]).ToArray());
    }
}
