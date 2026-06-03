namespace BuildingBlocks.Exceptions;

/// <summary>
/// Thrown when a MIANE tier-based limit is exceeded (trip count, member count).
/// Maps to HTTP 422 Unprocessable Entity.
/// </summary>
public class TierLimitExceededException : DomainException
{
    public int CurrentTier { get; }
    public string LimitType { get; }
    public int CurrentCount { get; }
    public int MaxAllowed { get; }

    public TierLimitExceededException(
        int currentTier,
        string limitType,
        int currentCount,
        int maxAllowed)
        : base(
            $"Tier limit exceeded: {limitType}. Current: {currentCount}, Max allowed: {maxAllowed} for tier {currentTier}. Upgrade to MIANE Pro for unlimited access.",
            "TIER_LIMIT_EXCEEDED")
    {
        CurrentTier = currentTier;
        LimitType = limitType;
        CurrentCount = currentCount;
        MaxAllowed = maxAllowed;
    }
}
