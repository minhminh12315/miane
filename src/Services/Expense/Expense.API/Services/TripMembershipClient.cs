using BuildingBlocks.Exceptions;
using System.Net;
using System.Net.Http.Headers;

namespace Expense.API.Services;

public interface ITripMembershipClient
{
    Task EnsureMemberAsync(Guid tripId, CancellationToken cancellationToken = default);
}

public sealed class TripMembershipClient : ITripMembershipClient
{
    private readonly HttpClient _httpClient;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<TripMembershipClient> _logger;

    public TripMembershipClient(
        HttpClient httpClient,
        IHttpContextAccessor httpContextAccessor,
        ILogger<TripMembershipClient> logger)
    {
        _httpClient = httpClient;
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
    }

    public async Task EnsureMemberAsync(Guid tripId, CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, $"trips/{tripId}/membership");

        var httpContext = _httpContextAccessor.HttpContext
            ?? throw new UnauthorizedAccessException("Missing HTTP context for membership check.");

        if (AuthenticationHeaderValue.TryParse(
                httpContext.Request.Headers.Authorization.FirstOrDefault(),
                out var authHeader))
        {
            request.Headers.Authorization = authHeader;
        }
        else
        {
            throw new UnauthorizedAccessException("Missing Authorization header for membership check.");
        }

        HttpResponseMessage response;
        try
        {
            response = await _httpClient.SendAsync(request, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed calling Trip membership for trip {TripId}", tripId);
            throw new DomainException(
                "Không thể xác minh thành viên chuyến đi. Thử lại sau.",
                "TRIP_MEMBERSHIP_UNAVAILABLE");
        }

        if (response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized)
        {
            throw new ForbiddenAccessException("Bạn không phải là thành viên của chuyến đi này.");
        }

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "Trip membership check returned {StatusCode} for trip {TripId}",
                (int)response.StatusCode,
                tripId);
            throw new DomainException(
                "Không thể xác minh thành viên chuyến đi.",
                "TRIP_MEMBERSHIP_CHECK_FAILED");
        }
    }
}
