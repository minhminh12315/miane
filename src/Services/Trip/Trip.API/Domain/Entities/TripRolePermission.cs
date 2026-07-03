using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripRolePermission : BaseEntity
{
    public Guid TripRoleId { get; set; }
    public string PermissionKey { get; set; } = string.Empty;
    public string? Description { get; set; }

    public TripRole Role { get; set; } = null!;
}
