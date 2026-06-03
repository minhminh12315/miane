using BuildingBlocks.AI.Contracts;

namespace BuildingBlocks.AI;

/// <summary>
/// Interface for AI-powered trip planning. Implementation talks to the
/// Python FastAPI service via HTTP.
/// </summary>
public interface IAiTripPlannerService
{
    Task<TripPlanSuggestion> SuggestPlanAsync(TripPlanRequest request, CancellationToken cancellationToken = default);
}
