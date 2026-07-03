using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripWeatherCache : BaseEntity
{
    public Guid TripId { get; set; }
    public string Destination { get; set; } = string.Empty;
    public DateOnly ForecastDate { get; set; }
    public string PayloadJson { get; set; } = "{}";
    public DateTime ExpiresAt { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
