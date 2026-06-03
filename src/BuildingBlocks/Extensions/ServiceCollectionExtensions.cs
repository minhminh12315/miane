using System.Reflection;
using BuildingBlocks.Behaviors;
using BuildingBlocks.Data;
using BuildingBlocks.EventBus;
using FluentValidation;
using MediatR;
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

        // EventBus — in-process implementation using MediatR
        services.AddScoped<IEventBus, InProcessEventBus>();

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
