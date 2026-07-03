using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripBooking : BaseEntity
{
    public Guid TripId { get; set; }
    public string Type { get; set; } = "Hotel";
    public string Title { get; set; } = string.Empty;
    public string? ConfirmationNumber { get; set; }
    public DateTime? StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public string? LocationName { get; set; }
    public string Status { get; set; } = "Planned";
    public string? AttachmentUrl { get; set; }
    public string? Notes { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
