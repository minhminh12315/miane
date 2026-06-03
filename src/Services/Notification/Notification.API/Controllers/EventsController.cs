using Microsoft.AspNetCore.Mvc;
using Notification.API.EventHandlers;

namespace Notification.API.Controllers;

/// <summary>
/// Internal webhook endpoint that receives integration events from other services.
/// In production, this should be protected with an internal API key or network-level security.
/// </summary>
[ApiController]
[Route("notifications/events")]
public class EventsController : ControllerBase
{
    private readonly NotificationEventProcessor _processor;

    public EventsController(NotificationEventProcessor processor)
    {
        _processor = processor;
    }

    [HttpPost]
    public async Task<IActionResult> ReceiveEvent([FromBody] IntegrationEventPayload payload, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(payload.EventType))
        {
            return BadRequest(new { message = "EventType is required." });
        }

        await _processor.ProcessEventAsync(payload, ct);
        return Accepted();
    }
}
