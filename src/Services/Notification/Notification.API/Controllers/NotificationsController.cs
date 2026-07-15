using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Notification.API.Data;

namespace Notification.API.Controllers;

[ApiController]
[Route("notifications")]
public class NotificationsController : ControllerBase
{
    private readonly NotificationDbContext _dbContext;

    public NotificationsController(NotificationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    /// <summary>
    /// Get the authenticated user's notification history.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var userId = GetUserId();
        var skip = (page - 1) * pageSize;

        var notifications = await _dbContext.NotificationLogs
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.SentAt)
            .Skip(skip)
            .Take(pageSize)
            .Select(n => new
            {
                n.Id,
                n.Title,
                n.Body,
                n.EventType,
                n.SentAt,
                n.IsRead,
                n.Data
            })
            .ToListAsync(ct);

        var unreadCount = await _dbContext.NotificationLogs
            .CountAsync(n => n.UserId == userId && !n.IsRead, ct);

        return Ok(new { notifications, unreadCount, page, pageSize });
    }

    /// <summary>
    /// Mark a notification as read.
    /// </summary>
    [HttpPut("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id, CancellationToken ct)
    {
        var userId = GetUserId();
        var notification = await _dbContext.NotificationLogs
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId, ct);

        if (notification is null)
        {
            return NotFound(new { message = "Không tìm thấy thông báo." });
        }

        notification.IsRead = true;
        await _dbContext.SaveChangesAsync(ct);

        return NoContent();
    }

    /// <summary>
    /// Mark all notifications as read for the current user.
    /// </summary>
    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead(CancellationToken ct)
    {
        var userId = GetUserId();
        await _dbContext.NotificationLogs
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true), ct);

        return NoContent();
    }
}
