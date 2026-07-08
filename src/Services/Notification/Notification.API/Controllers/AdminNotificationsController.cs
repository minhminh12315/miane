using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Notification.API.Data;

namespace Notification.API.Controllers
{
    /// <summary>
    /// Admin-only, cross-user view of all notification logs (for the admin dashboard).
    /// Regular endpoints on NotificationsController are self-scoped by design;
    /// this is the one exception, gated behind the "Admin" role.
    /// </summary>
    [ApiController]
    [Route("notifications/admin")]
    [Authorize(Roles = "Admin")]
    public class AdminNotificationsController : ControllerBase
    {
        private readonly NotificationDbContext _db;

        public AdminNotificationsController(NotificationDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> ListAllNotifications(CancellationToken ct)
        {
            var notifications = await _db.NotificationLogs
                .OrderByDescending(n => n.SentAt)
                .Select(n => new
                {
                    id = n.Id,
                    userId = n.UserId,
                    title = n.Title,
                    eventType = n.EventType,
                    isRead = n.IsRead,
                    sentAt = n.SentAt
                })
                .ToListAsync(ct);

            return Ok(notifications);
        }
    }
}
