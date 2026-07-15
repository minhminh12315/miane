using FirebaseAdmin.Messaging;

namespace BuildingBlocks.Notifications;

public sealed class FirebaseNotificationService : IFirebaseNotificationService
{
    public async Task<string> SendAsync(FirebaseNotificationRequest request, CancellationToken cancellationToken = default)
    {
        if (FirebaseAdmin.FirebaseApp.DefaultInstance is null)
        {
            throw new InvalidOperationException("Firebase is not configured. Set Firebase:ServiceAccountPath or GOOGLE_APPLICATION_CREDENTIALS.");
        }

        if (string.IsNullOrWhiteSpace(request.Token))
        {
            throw new ArgumentException("A target FCM token is required.", nameof(request));
        }

        var message = new Message
        {
            Token = request.Token,
            Notification = new Notification
            {
                Title = request.Title,
                Body = request.Body
            },
            Data = request.Data
        };

        ApplyPlatformOptions(message, request.Platform);

        return await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }

    private static void ApplyPlatformOptions(Message message, string platform)
    {
        switch (platform.Trim().ToLowerInvariant())
        {
            case "ios":
            case "macos":
                message.Apns = new ApnsConfig
                {
                    Headers = new Dictionary<string, string>
                    {
                        ["apns-priority"] = "10"
                    },
                    Aps = new Aps
                    {
                        Sound = "default"
                    }
                };
                break;
            case "web":
                message.Webpush = new WebpushConfig
                {
                    Notification = new WebpushNotification
                    {
                        Icon = "/icons/Icon-192.png",
                        Badge = "/icons/Icon-192.png"
                    }
                };
                break;
        }
    }
}
