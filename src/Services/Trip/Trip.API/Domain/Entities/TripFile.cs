using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripFile : BaseEntity
{
    public Guid TripId { get; set; }
    public string Folder { get; set; } = "General";
    public string FileName { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public string? ContentType { get; set; }
    public long? FileSizeBytes { get; set; }
    public Guid UploadedByUserId { get; set; }
    public string Permissions { get; set; } = "[]";
    public string Tags { get; set; } = "[]";

    public TripEntity Trip { get; set; } = null!;
}
