using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

/// <summary>
/// A single leg/segment of a multi-stop trip, e.g. Hà Nội → Đà Nẵng → Sài Gòn.
/// Each leg has its own destination and date range, ordered within the trip.
/// A trip with a single destination simply has zero or one leg.
/// </summary>
public class TripLeg : BaseEntity
{
    public Guid TripId { get; set; }

    /// <summary>Position of this leg within the trip (0-based, ascending).</summary>
    public int Order { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? DestinationCity { get; set; }
    public string? DestinationCountry { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? Notes { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
