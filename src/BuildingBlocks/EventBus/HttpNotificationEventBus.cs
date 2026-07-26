using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BuildingBlocks.EventBus;

public sealed class NotificationEventBusOptions
{
    public const string SectionName = "Services:Notification";

    /// <summary>Base URL of Notification.API, e.g. http://notification-api:5130/</summary>
    public string? BaseUrl { get; set; }

    /// <summary>Must match Notification Internal:ApiKey.</summary>
    public string? ApiKey { get; set; }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(BaseUrl) && !string.IsNullOrWhiteSpace(ApiKey);
}

/// <summary>
/// Forwards integration events to Notification.API's internal webhook.
/// </summary>
public sealed class HttpNotificationEventBus : IEventBus
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = null
    };

    private readonly HttpClient _httpClient;
    private readonly NotificationEventBusOptions _options;
    private readonly ILogger<HttpNotificationEventBus> _logger;

    public HttpNotificationEventBus(
        HttpClient httpClient,
        IOptions<NotificationEventBusOptions> options,
        ILogger<HttpNotificationEventBus> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task PublishAsync(IIntegrationEvent integrationEvent, CancellationToken cancellationToken = default)
    {
        if (!_options.IsConfigured)
        {
            _logger.LogDebug(
                "Skipping HTTP notification publish for {EventType}: Services:Notification not configured.",
                integrationEvent.EventType);
            return;
        }

        var payload = BuildPayload(integrationEvent);
        using var request = new HttpRequestMessage(HttpMethod.Post, "notifications/events")
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.TryAddWithoutValidation("X-Internal-Api-Key", _options.ApiKey);

        try
        {
            var response = await _httpClient.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogWarning(
                    "Notification webhook returned {StatusCode} for {EventType}: {Body}",
                    (int)response.StatusCode,
                    integrationEvent.EventType,
                    body);
            }
        }
        catch (Exception ex)
        {
            // Don't fail the business transaction if notifications are down.
            _logger.LogError(ex, "Failed to forward {EventType} to Notification.API", integrationEvent.EventType);
        }
    }

    public async Task PublishAsync(IEnumerable<IIntegrationEvent> integrationEvents, CancellationToken cancellationToken = default)
    {
        foreach (var integrationEvent in integrationEvents)
        {
            await PublishAsync(integrationEvent, cancellationToken);
        }
    }

    private static object BuildPayload(IIntegrationEvent integrationEvent)
    {
        using var document = JsonSerializer.SerializeToDocument(integrationEvent, integrationEvent.GetType(), SerializerOptions);
        var data = new Dictionary<string, object?>();
        foreach (var property in document.RootElement.EnumerateObject())
        {
            if (property.Name is "EventId" or "OccurredOn" or "EventType")
            {
                continue;
            }

            data[property.Name] = property.Value.Clone();
        }

        return new
        {
            EventType = integrationEvent.EventType,
            EventId = integrationEvent.EventId,
            OccurredOn = integrationEvent.OccurredOn,
            Data = data
        };
    }
}

/// <summary>
/// Publishes locally (MediatR) and optionally forwards to Notification.API.
/// </summary>
public sealed class CompositeEventBus : IEventBus
{
    private readonly InProcessEventBus _inProcess;
    private readonly HttpNotificationEventBus _http;

    public CompositeEventBus(InProcessEventBus inProcess, HttpNotificationEventBus http)
    {
        _inProcess = inProcess;
        _http = http;
    }

    public async Task PublishAsync(IIntegrationEvent integrationEvent, CancellationToken cancellationToken = default)
    {
        await _inProcess.PublishAsync(integrationEvent, cancellationToken);
        await _http.PublishAsync(integrationEvent, cancellationToken);
    }

    public async Task PublishAsync(IEnumerable<IIntegrationEvent> integrationEvents, CancellationToken cancellationToken = default)
    {
        foreach (var integrationEvent in integrationEvents)
        {
            await PublishAsync(integrationEvent, cancellationToken);
        }
    }
}
