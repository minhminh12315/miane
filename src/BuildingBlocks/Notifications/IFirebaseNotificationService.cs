namespace BuildingBlocks.Notifications;

public interface IFirebaseNotificationService
{
    Task<string> SendAsync(FirebaseNotificationRequest request, CancellationToken cancellationToken = default);
}
