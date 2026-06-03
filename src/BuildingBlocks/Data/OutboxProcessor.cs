using BuildingBlocks.EventBus;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace BuildingBlocks.Data;

/// <summary>
/// Background service that polls the outbox table for unprocessed messages
/// and publishes them via the <see cref="IEventBus"/>. Implements at-least-once
/// delivery with retry logic and dead-letter handling.
/// </summary>
public sealed class OutboxProcessor<TContext> : BackgroundService
    where TContext : BaseDbContext
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<OutboxProcessor<TContext>> _logger;
    private readonly TimeSpan _pollingInterval = TimeSpan.FromSeconds(5);
    private const int MaxRetryCount = 3;
    private const int BatchSize = 50;

    public OutboxProcessor(
        IServiceScopeFactory scopeFactory,
        ILogger<OutboxProcessor<TContext>> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("[Outbox] Processor started for {ContextType}", typeof(TContext).Name);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOutboxMessagesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Outbox] Error during outbox processing cycle");
            }

            await Task.Delay(_pollingInterval, stoppingToken);
        }
    }

    private async Task ProcessOutboxMessagesAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<TContext>();
        var eventBus = scope.ServiceProvider.GetRequiredService<IEventBus>();

        var messages = await dbContext.OutboxMessages
            .Where(m => m.ProcessedOn == null && m.RetryCount < MaxRetryCount)
            .OrderBy(m => m.OccurredOn)
            .Take(BatchSize)
            .ToListAsync(cancellationToken);

        if (messages.Count == 0) return;

        _logger.LogInformation("[Outbox] Processing {Count} outbox messages", messages.Count);

        foreach (var message in messages)
        {
            try
            {
                var eventType = System.Type.GetType(message.Type);
                if (eventType is null)
                {
                    _logger.LogWarning("[Outbox] Unknown event type: {Type}. Marking as dead-letter.", message.Type);
                    message.Error = $"Unknown type: {message.Type}";
                    message.ProcessedOn = DateTime.UtcNow;
                    continue;
                }

                var domainEvent = JsonSerializer.Deserialize(message.Content, eventType);
                if (domainEvent is IIntegrationEvent integrationEvent)
                {
                    await eventBus.PublishAsync(integrationEvent, cancellationToken);
                }

                message.ProcessedOn = DateTime.UtcNow;
                message.Error = null;

                _logger.LogInformation(
                    "[Outbox] Published {EventType} (MessageId: {MessageId})",
                    message.Type, message.Id);
            }
            catch (Exception ex)
            {
                message.RetryCount++;
                message.Error = ex.Message;

                _logger.LogWarning(ex,
                    "[Outbox] Failed to publish {EventType} (MessageId: {MessageId}, Retry: {RetryCount}/{MaxRetry})",
                    message.Type, message.Id, message.RetryCount, MaxRetryCount);
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
