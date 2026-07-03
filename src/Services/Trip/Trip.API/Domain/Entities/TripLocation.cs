using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripLocation : BaseEntity
{
    public Guid TripId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = "Attraction";
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string? Address { get; set; }
    public string? Notes { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
