using BuildingBlocks.AI.Contracts;
using Microsoft.Extensions.Logging;
using System.Net.Http.Json;

namespace BuildingBlocks.AI;

/// <summary>
/// HTTP-based implementation of <see cref="IAiTripPlannerService"/> that forwards
/// planning requests to the Python FastAPI AI engine.
/// </summary>
public sealed class HttpAiTripPlannerService : IAiTripPlannerService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<HttpAiTripPlannerService> _logger;

    public HttpAiTripPlannerService(HttpClient httpClient, ILogger<HttpAiTripPlannerService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<TripPlanSuggestion> SuggestPlanAsync(TripPlanRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("/api/planner/suggest", request, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<TripPlanSuggestion>(cancellationToken: cancellationToken);
            return result ?? new TripPlanSuggestion { IsSuccess = false, ErrorMessage = "Empty response from AI service" };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "[AI-Planner] Failed to reach AI service. Returning empty suggestion.");
            return new TripPlanSuggestion
            {
                IsSuccess = false,
                ErrorMessage = $"AI planner service unavailable: {ex.Message}"
            };
        }
    }
}
