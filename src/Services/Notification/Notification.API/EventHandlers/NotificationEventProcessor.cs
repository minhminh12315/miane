using BuildingBlocks.Notifications;
using Microsoft.Extensions.Logging;
using Notification.API.Data;

namespace Notification.API.EventHandlers;

/// <summary>
/// Processes integration events received via the webhook endpoint.
/// Routes events to the appropriate notification handler.
/// </summary>
public sealed class NotificationEventProcessor
{
    private readonly NotificationDbContext _dbContext;
    private readonly IFirebaseNotificationService _firebaseService;
    private readonly ILogger<NotificationEventProcessor> _logger;

    public NotificationEventProcessor(
        NotificationDbContext dbContext,
        IFirebaseNotificationService firebaseService,
        ILogger<NotificationEventProcessor> logger)
    {
        _dbContext = dbContext;
        _firebaseService = firebaseService;
        _logger = logger;
    }

    public async Task ProcessEventAsync(IntegrationEventPayload payload, CancellationToken cancellationToken)
    {
        _logger.LogInformation("[Notification] Processing event: {EventType}", payload.EventType);

        switch (payload.EventType)
        {
            case "ExpenseCreatedEvent":
                await HandleExpenseCreatedAsync(payload, cancellationToken);
                break;
            case "DebtSettledEvent":
                await HandleDebtSettledAsync(payload, cancellationToken);
                break;
            case "MemberJoinedEvent":
                await HandleMemberJoinedAsync(payload, cancellationToken);
                break;
            case "TripLimitReachedEvent":
                await HandleTripLimitReachedAsync(payload, cancellationToken);
                break;
            default:
                _logger.LogWarning("[Notification] Unknown event type: {EventType}", payload.EventType);
                break;
        }
    }

    private async Task HandleExpenseCreatedAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var handler = new ExpenseCreatedHandler(_dbContext, _firebaseService, _logger);
        await handler.HandleAsync(payload, ct);
    }

    private async Task HandleDebtSettledAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var handler = new DebtSettledHandler(_dbContext, _firebaseService, _logger);
        await handler.HandleAsync(payload, ct);
    }

    private async Task HandleMemberJoinedAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var handler = new MemberJoinedHandler(_dbContext, _firebaseService, _logger);
        await handler.HandleAsync(payload, ct);
    }

    private async Task HandleTripLimitReachedAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var handler = new TripLimitReachedHandler(_dbContext, _firebaseService, _logger);
        await handler.HandleAsync(payload, ct);
    }
}

/// <summary>
/// Generic payload received from other services via the events webhook.
/// </summary>
public sealed class IntegrationEventPayload
{
    public string EventType { get; set; } = string.Empty;
    public Guid EventId { get; set; }
    public DateTime OccurredOn { get; set; }
    public Dictionary<string, object> Data { get; set; } = new();

    public T? GetData<T>(string key)
    {
        if (Data.TryGetValue(key, out var value))
        {
            if (value is System.Text.Json.JsonElement element)
            {
                return System.Text.Json.JsonSerializer.Deserialize<T>(element.GetRawText());
            }
            return (T)Convert.ChangeType(value, typeof(T));
        }
        return default;
    }

    public string GetString(string key) => GetData<string>(key) ?? string.Empty;
    public Guid GetGuid(string key)
    {
        var val = GetString(key);
        return Guid.TryParse(val, out var guid) ? guid : Guid.Empty;
    }
    public decimal GetDecimal(string key)
    {
        if (Data.TryGetValue(key, out var value))
        {
            if (value is System.Text.Json.JsonElement element)
            {
                return element.GetDecimal();
            }
            return Convert.ToDecimal(value);
        }
        return 0m;
    }
    public int GetInt(string key)
    {
        if (Data.TryGetValue(key, out var value))
        {
            if (value is System.Text.Json.JsonElement element)
            {
                return element.GetInt32();
            }
            return Convert.ToInt32(value);
        }
        return 0;
    }
}

// Individual event handlers

public sealed class ExpenseCreatedHandler : BaseNotificationEventHandler
{
    public ExpenseCreatedHandler(NotificationDbContext db, IFirebaseNotificationService fb, ILogger logger)
        : base(db, fb, logger) { }

    public async Task HandleAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var description = payload.GetString("Description");
        var amount = payload.GetDecimal("Amount");
        var currency = payload.GetString("Currency");
        var paidByUserId = payload.GetGuid("PaidByUserId");
        var tripId = payload.GetGuid("TripId");

        // In a full implementation, we'd look up trip members from a cache or query
        // For now, notify the payer that their expense was recorded
        await SendToUserAsync(
            paidByUserId,
            "💰 Expense Added",
            $"You added: {description} — {amount:N0} {currency}",
            "ExpenseCreatedEvent",
            new Dictionary<string, string>
            {
                { "tripId", tripId.ToString() },
                { "expenseId", payload.GetGuid("ExpenseId").ToString() }
            },
            ct);
    }
}

public sealed class DebtSettledHandler : BaseNotificationEventHandler
{
    public DebtSettledHandler(NotificationDbContext db, IFirebaseNotificationService fb, ILogger logger)
        : base(db, fb, logger) { }

    public async Task HandleAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var fromUserId = payload.GetGuid("FromUserId");
        var toUserId = payload.GetGuid("ToUserId");
        var amount = payload.GetDecimal("Amount");
        var currency = payload.GetString("Currency");

        await SendToUserAsync(
            toUserId,
            "✅ Debt Settled",
            $"Payment received: {amount:N0} {currency}",
            "DebtSettledEvent",
            new Dictionary<string, string>
            {
                { "debtRecordId", payload.GetGuid("DebtRecordId").ToString() }
            },
            ct);

        await SendToUserAsync(
            fromUserId,
            "✅ Payment Confirmed",
            $"Your payment of {amount:N0} {currency} has been recorded",
            "DebtSettledEvent",
            cancellationToken: ct);
    }
}

public sealed class MemberJoinedHandler : BaseNotificationEventHandler
{
    public MemberJoinedHandler(NotificationDbContext db, IFirebaseNotificationService fb, ILogger logger)
        : base(db, fb, logger) { }

    public async Task HandleAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var tripName = payload.GetString("TripName");
        var userId = payload.GetGuid("UserId");
        var memberCount = payload.GetInt("MemberCount");

        await SendToUserAsync(
            userId,
            "👋 Welcome!",
            $"You joined '{tripName}' — {memberCount} members in the group",
            "MemberJoinedEvent",
            new Dictionary<string, string>
            {
                { "tripId", payload.GetGuid("TripId").ToString() }
            },
            ct);
    }
}

public sealed class TripLimitReachedHandler : BaseNotificationEventHandler
{
    public TripLimitReachedHandler(NotificationDbContext db, IFirebaseNotificationService fb, ILogger logger)
        : base(db, fb, logger) { }

    public async Task HandleAsync(IntegrationEventPayload payload, CancellationToken ct)
    {
        var tripName = payload.GetString("TripName");
        var ownerUserId = payload.GetGuid("OwnerUserId");
        var maxMembers = payload.GetInt("MaxMembers");

        await SendToUserAsync(
            ownerUserId,
            "⚠️ Member Limit Reached",
            $"Your trip '{tripName}' has reached the {maxMembers}-member limit. Upgrade to MIANE Pro for unlimited members.",
            "TripLimitReachedEvent",
            new Dictionary<string, string>
            {
                { "tripId", payload.GetGuid("TripId").ToString() }
            },
            ct);
    }
}
