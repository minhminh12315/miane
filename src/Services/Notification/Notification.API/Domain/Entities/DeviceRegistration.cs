using BuildingBlocks.Domain;

namespace Notification.API.Domain.Entities;

public class DeviceRegistration : BaseEntity
{
    public Guid UserId { get; set; }
    public string FcmToken { get; set; } = string.Empty;
    public string DevicePlatform { get; set; } = string.Empty; // "ios", "android", "web"
    public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}
