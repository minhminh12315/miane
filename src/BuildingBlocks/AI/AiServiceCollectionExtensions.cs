using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BuildingBlocks.AI;

/// <summary>
/// DI registration for AI service HTTP clients with Polly resilience policies.
/// </summary>
public static class AiServiceCollectionExtensions
{
    public static IServiceCollection AddAiServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var section = configuration.GetSection("AiServices");
        services.Configure<AiServiceOptions>(section);

        var options = section.Get<AiServiceOptions>() ?? new AiServiceOptions();

        services.AddHttpClient<IAiOcrService, HttpAiOcrService>(client =>
        {
            client.BaseAddress = new Uri(options.BaseUrl);
            client.Timeout = TimeSpan.FromSeconds(options.TimeoutSeconds);

            if (!string.IsNullOrWhiteSpace(options.ApiKey))
            {
                client.DefaultRequestHeaders.Add("X-Api-Key", options.ApiKey);
            }
        });

        services.AddHttpClient<IAiTripPlannerService, HttpAiTripPlannerService>(client =>
        {
            client.BaseAddress = new Uri(options.BaseUrl);
            client.Timeout = TimeSpan.FromSeconds(options.TimeoutSeconds);

            if (!string.IsNullOrWhiteSpace(options.ApiKey))
            {
                client.DefaultRequestHeaders.Add("X-Api-Key", options.ApiKey);
            }
        });

        return services;
    }
}
