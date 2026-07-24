using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Notification.API.Data;
using Notification.API.Domain.Entities;
using System.Text.Json;

namespace Notification.API.EventHandlers;

/// <summary>
/// Base class for event handlers that processes integration events received
/// via the events webhook endpoint and persists in-app notifications to the database.
/// </summary>
public abstract class BaseNotificationEventHandler
{
    protected readonly NotificationDbContext DbContext;
    protected readonly ILogger Logger;

    protected BaseNotificationEventHandler(
        NotificationDbContext dbContext,
        ILogger logger)
    {
        DbContext = dbContext;
        Logger = logger;
    }

    protected async Task SendToTripMembersAsync(
        List<Guid> userIds,
        string title,
        string body,
        string eventType,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        await PersistNotificationsAsync(
            userIds,
            title,
            body,
            eventType,
            data,
            cancellationToken);
    }

    protected async Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        string eventType,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        await SendToTripMembersAsync(
            new List<Guid> { userId },
            title,
            body,
            eventType,
            data,
            cancellationToken);
    }

    private async Task PersistNotificationsAsync(
        IReadOnlyCollection<Guid> userIds,
        string title,
        string body,
        string eventType,
        Dictionary<string, string>? data,
        CancellationToken cancellationToken)
    {
        if (userIds.Count == 0)
        {
            return;
        }

        var logs = userIds.Select(uid => new NotificationLog
        {
            UserId = uid,
            Title = title,
            Body = body,
            EventType = eventType,
            SentAt = DateTime.UtcNow,
            Data = data is not null ? JsonSerializer.Serialize(data) : null
        }).ToList();

        await DbContext.NotificationLogs.AddRangeAsync(logs, cancellationToken);
        await DbContext.SaveChangesAsync(cancellationToken);

        Logger.LogInformation(
            "[Notification] Stored {Count} in-app notification(s) for event {EventType}",
            logs.Count,
            eventType);
    }
}
