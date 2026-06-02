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

        return await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }
}
