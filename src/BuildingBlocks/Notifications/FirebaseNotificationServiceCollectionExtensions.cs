using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BuildingBlocks.Notifications;

public static class FirebaseNotificationServiceCollectionExtensions
{
    public static IServiceCollection AddFirebaseNotifications(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var section = configuration.GetSection("Firebase");
        services.Configure<FirebaseNotificationOptions>(section);

        if (FirebaseApp.DefaultInstance is null)
        {
            var options = section.Get<FirebaseNotificationOptions>() ?? new FirebaseNotificationOptions();
            var appOptions = new AppOptions();

            if (!string.IsNullOrWhiteSpace(options.ServiceAccountPath) && File.Exists(options.ServiceAccountPath))
            {
                appOptions.Credential = GoogleCredential.FromFile(options.ServiceAccountPath);
            }
            else if (!string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")))
            {
                appOptions.Credential = GoogleCredential.GetApplicationDefault();
            }
            else
            {
                services.AddSingleton<IFirebaseNotificationService, FirebaseNotificationService>();
                return services;
            }

            if (!string.IsNullOrWhiteSpace(options.ProjectId))
            {
                appOptions.ProjectId = options.ProjectId;
            }

            FirebaseApp.Create(appOptions);
        }

        services.AddSingleton<IFirebaseNotificationService, FirebaseNotificationService>();
        return services;
    }
}
