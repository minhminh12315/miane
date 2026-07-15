using BuildingBlocks.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Notification.API.Data;
using Notification.API.Domain.Entities;
using System.Text.Json;

namespace Notification.API.EventHandlers;

/// <summary>
/// Base class for event handlers that processes integration events received
/// via the events webhook endpoint. Looks up device tokens and dispatches FCM push notifications.
/// </summary>
public abstract class BaseNotificationEventHandler
{
    protected readonly NotificationDbContext DbContext;
    protected readonly IFirebaseNotificationService FirebaseService;
    protected readonly ILogger Logger;

    protected BaseNotificationEventHandler(
        NotificationDbContext dbContext,
        IFirebaseNotificationService firebaseService,
        ILogger logger)
    {
        DbContext = dbContext;
        FirebaseService = firebaseService;
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
        var devices = await DbContext.DeviceRegistrations
            .Where(d => userIds.Contains(d.UserId) && d.IsActive)
            .ToListAsync(cancellationToken);

        foreach (var device in devices)
        {
            try
            {
                await FirebaseService.SendAsync(new FirebaseNotificationRequest
                {
                    Token = device.FcmToken,
                    Platform = device.DevicePlatform,
                    Title = title,
                    Body = body,
                    Data = data ?? new()
                }, cancellationToken);
            }
            catch (Exception ex)
            {
                Logger.LogWarning(ex,
                    "[Notification] Failed to send FCM to token {Token} for user {UserId}",
                    device.FcmToken[..Math.Min(10, device.FcmToken.Length)] + "...", device.UserId);
            }
        }

        // Log notifications
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
    }

    protected async Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        string eventType,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        await SendToTripMembersAsync(new List<Guid> { userId }, title, body, eventType, data, cancellationToken);
    }
}
