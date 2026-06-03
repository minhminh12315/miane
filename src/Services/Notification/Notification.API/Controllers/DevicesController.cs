using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Notification.API.Data;
using Notification.API.Domain.Entities;

namespace Notification.API.Controllers;

[ApiController]
[Route("notifications/devices")]
public class DevicesController : ControllerBase
{
    private readonly NotificationDbContext _dbContext;

    public DevicesController(NotificationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDeviceRequest request, CancellationToken ct)
    {
        var userId = GetUserId();

        // Upsert: update existing token or create new
        var existing = await _dbContext.DeviceRegistrations
            .FirstOrDefaultAsync(d => d.FcmToken == request.FcmToken, ct);

        if (existing is not null)
        {
            existing.UserId = userId;
            existing.DevicePlatform = request.Platform;
            existing.IsActive = true;
            existing.RegisteredAt = DateTime.UtcNow;
        }
        else
        {
            var device = new DeviceRegistration
            {
                UserId = userId,
                FcmToken = request.FcmToken,
                DevicePlatform = request.Platform,
                IsActive = true
            };
            await _dbContext.DeviceRegistrations.AddAsync(device, ct);
        }

        await _dbContext.SaveChangesAsync(ct);
        return Ok(new { message = "Device registered successfully." });
    }

    [HttpDelete("{token}")]
    public async Task<IActionResult> Unregister(string token, CancellationToken ct)
    {
        var device = await _dbContext.DeviceRegistrations
            .FirstOrDefaultAsync(d => d.FcmToken == token, ct);

        if (device is not null)
        {
            device.IsActive = false;
            await _dbContext.SaveChangesAsync(ct);
        }

        return NoContent();
    }
}

public sealed record RegisterDeviceRequest(string FcmToken, string Platform);
