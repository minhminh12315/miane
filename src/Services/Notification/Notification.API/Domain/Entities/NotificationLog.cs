using BuildingBlocks.Domain;

namespace Notification.API.Domain.Entities;

public class NotificationLog : BaseEntity
{
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public bool IsRead { get; set; }
    public string? Data { get; set; } // JSON additional data
}
