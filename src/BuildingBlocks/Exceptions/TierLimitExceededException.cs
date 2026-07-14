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
            $"Bạn đã vượt giới hạn gói: {limitType}. Hiện có: {currentCount}, tối đa: {maxAllowed}. Nâng cấp MIANE VIP để dùng không giới hạn.",
            "TIER_LIMIT_EXCEEDED")
    {
        CurrentTier = currentTier;
        LimitType = limitType;
        CurrentCount = currentCount;
        MaxAllowed = maxAllowed;
    }
}
