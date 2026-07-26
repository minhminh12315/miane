using Microsoft.AspNetCore.Mvc;
using Notification.API.EventHandlers;

namespace Notification.API.Controllers;

/// <summary>
/// Internal webhook for integration events from other services.
/// Requires header <c>X-Internal-Api-Key</c> matching configuration
/// <c>Internal:ApiKey</c> (or env <c>INTERNAL_API_KEY</c>).
/// </summary>
[ApiController]
[Route("notifications/events")]
public class EventsController : ControllerBase
{
    private readonly NotificationEventProcessor _processor;
    private readonly IConfiguration _configuration;

    public EventsController(NotificationEventProcessor processor, IConfiguration configuration)
    {
        _processor = processor;
        _configuration = configuration;
    }

    [HttpPost]
    public async Task<IActionResult> ReceiveEvent([FromBody] IntegrationEventPayload payload, CancellationToken ct)
    {
        var expectedKey = _configuration["Internal:ApiKey"];
        if (string.IsNullOrWhiteSpace(expectedKey))
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = "Internal event API key is not configured."
            });
        }

        var providedKey = Request.Headers["X-Internal-Api-Key"].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(providedKey)
            || !CryptographicEquals(expectedKey, providedKey))
        {
            return Unauthorized(new { message = "Invalid or missing internal API key." });
        }

        if (string.IsNullOrWhiteSpace(payload.EventType))
        {
            return BadRequest(new { message = "EventType is required." });
        }

        await _processor.ProcessEventAsync(payload, ct);
        return Accepted();
    }

    private static bool CryptographicEquals(string expected, string provided)
    {
        var expectedBytes = System.Text.Encoding.UTF8.GetBytes(expected);
        var providedBytes = System.Text.Encoding.UTF8.GetBytes(provided);
        return expectedBytes.Length == providedBytes.Length
            && System.Security.Cryptography.CryptographicOperations.FixedTimeEquals(expectedBytes, providedBytes);
    }
}
