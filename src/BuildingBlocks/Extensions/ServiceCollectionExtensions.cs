using System.Reflection;
using BuildingBlocks.Behaviors;
using BuildingBlocks.Data;
using BuildingBlocks.EventBus;
using FluentValidation;
using MediatR;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BuildingBlocks.Extensions;

/// <summary>
/// Convenience extension to register all BuildingBlocks infrastructure services
/// (MediatR, FluentValidation, Pipeline Behaviors, EventBus) from a calling assembly.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Registers MediatR handlers and FluentValidation validators found in the
    /// specified assembly, plus shared pipeline behaviors and the event bus.
    /// </summary>
    public static IServiceCollection AddBuildingBlocks(
        this IServiceCollection services,
        Assembly handlerAssembly)
    {
        // MediatR — scan the calling service assembly for handlers
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(handlerAssembly);
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        });

        // FluentValidation — scan the same assembly for validators
        services.AddValidatorsFromAssembly(handlerAssembly);

        // EventBus — in-process + optional HTTP forward to Notification.API
        services.AddScoped<InProcessEventBus>();
        services.AddScoped<IEventBus>(sp =>
        {
            var inProcess = sp.GetRequiredService<InProcessEventBus>();
            var http = sp.GetService<HttpNotificationEventBus>();
            return http is null
                ? inProcess
                : new CompositeEventBus(inProcess, http);
        });

        return services;
    }

    /// <summary>
    /// Registers HTTP forwarding of integration events to Notification.API
    /// when <c>Services:Notification:BaseUrl</c> and <c>ApiKey</c> are set.
    /// </summary>
    public static IServiceCollection AddNotificationEventForwarding(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<NotificationEventBusOptions>(
            configuration.GetSection(NotificationEventBusOptions.SectionName));

        var options = configuration
            .GetSection(NotificationEventBusOptions.SectionName)
            .Get<NotificationEventBusOptions>();

        if (options is null || !options.IsConfigured)
        {
            return services;
        }

        services.AddHttpClient<HttpNotificationEventBus>((_, client) =>
        {
            var baseUrl = options.BaseUrl!.EndsWith('/')
                ? options.BaseUrl
                : $"{options.BaseUrl}/";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);
        });

        return services;
    }

    /// <summary>
    /// Registers the outbox processor background service for the specified DbContext type.
    /// </summary>
    public static IServiceCollection AddOutboxProcessor<TContext>(this IServiceCollection services)
        where TContext : BaseDbContext
    {
        services.AddHostedService<OutboxProcessor<TContext>>();
        return services;
    }
}
