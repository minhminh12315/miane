using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripRole : BaseEntity
{
    private readonly List<TripRolePermission> _permissions = new();

    public Guid TripId { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Permissions { get; set; } = "[]";
    public bool IsSystem { get; set; }

    public TripEntity Trip { get; set; } = null!;
    public IReadOnlyCollection<TripRolePermission> RolePermissions => _permissions.AsReadOnly();

    public void AddPermission(string permissionKey, string? description = null)
    {
        _permissions.Add(new TripRolePermission
        {
            TripRoleId = Id,
            PermissionKey = permissionKey,
            Description = description
        });
    }
}
