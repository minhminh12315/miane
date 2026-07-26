using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace BuildingBlocks.Middleware;

/// <summary>
/// Prevents clients from forging identity by stripping inbound
/// <c>X-User-Id</c> / <c>X-User-Tier</c> headers and re-deriving them only
/// from a validated JWT (typically forwarded by the gateway).
/// </summary>
public sealed class TrustedUserHeadersMiddleware
{
    public const string UserIdHeader = "X-User-Id";
    public const string UserTierHeader = "X-User-Tier";

    private readonly RequestDelegate _next;

    public TrustedUserHeadersMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        context.Request.Headers.Remove(UserIdHeader);
        context.Request.Headers.Remove(UserTierHeader);

        var user = context.User;
        if (user.Identity?.IsAuthenticated == true)
        {
            var userId = user.FindFirst("sub")?.Value
                ?? user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? user.FindFirst(ClaimTypes.Name)?.Value;

            if (!string.IsNullOrWhiteSpace(userId))
            {
                context.Request.Headers[UserIdHeader] = userId;
            }

            var userTier = user.FindFirst("UserTier")?.Value ?? "0";
            context.Request.Headers[UserTierHeader] = userTier;
        }

        await _next(context);
    }
}
