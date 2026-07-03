using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripActivity : BaseEntity
{
    public Guid TripPlanId { get; set; }
    public Guid TripId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slot { get; set; } = "Morning";
    public string Category { get; set; } = "Activity";
    public string? LocationName { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public DateTime? StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public string? Notes { get; set; }
    public int SortOrder { get; set; }
    public string? ColorHex { get; set; }

    public TripPlan Plan { get; set; } = null!;
    public TripEntity Trip { get; set; } = null!;
}
