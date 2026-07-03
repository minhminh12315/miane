using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripImage : BaseEntity
{
    public Guid TripId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? Destination { get; set; }
    public string? Prompt { get; set; }
    public string? CacheKey { get; set; }
    public bool IsCover { get; set; }
    public bool IsGenerated { get; set; }
    public Guid? UploadedByUserId { get; set; }

    public TripEntity Trip { get; set; } = null!;
}
