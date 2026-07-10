using BuildingBlocks.Exceptions;
using Expense.API.Domain.Enums;

namespace Expense.API.Services;

public sealed record SplitParticipantInput(
    Guid UserId,
    decimal? Amount = null,
    decimal? Percentage = null,
    decimal? Weight = null,
    decimal ParticipationRatio = 1m,
    bool IsExcluded = false);

public sealed record SplitShare(Guid UserId, decimal Amount);

public sealed record SplitCalculationResult(IReadOnlyList<SplitShare> Shares, decimal RoundingDelta);

public sealed class SplitCalculationService
{
    public SplitCalculationResult Calculate(
        decimal amount,
        SplitType splitType,
        IReadOnlyCollection<SplitParticipantInput> participants,
        int currencyScale = 0)
    {
        if (amount < 0)
        {
            throw new DomainException("Split amount cannot be negative.", "INVALID_SPLIT_AMOUNT");
        }

        if (splitType == SplitType.TripPool)
        {
            return new SplitCalculationResult(Array.Empty<SplitShare>(), 0m);
        }

        var eligible = participants
            .Where(p => !p.IsExcluded && p.UserId != Guid.Empty)
            .ToList();

        if (eligible.Count == 0)
        {
            throw new DomainException("At least one eligible participant is required.", "NO_ELIGIBLE_PARTICIPANTS");
        }

        var rawShares = splitType switch
        {
            SplitType.Equal => CalculateByWeight(amount, eligible.Select(p => (p.UserId, Weight: p.ParticipationRatio))),
            SplitType.Custom => CalculateCustom(amount, eligible),
            SplitType.Percentage => CalculatePercentage(amount, eligible),
            _ => throw new DomainException("Unsupported split type.", "UNSUPPORTED_SPLIT_TYPE")
        };

        return RoundAndDistributeDelta(amount, rawShares, currencyScale);
    }

    public SplitCalculationResult CalculateWeighted(
        decimal amount,
        IReadOnlyCollection<SplitParticipantInput> participants,
        int currencyScale = 0)
    {
        var eligible = participants
            .Where(p => !p.IsExcluded && p.UserId != Guid.Empty)
            .ToList();

        return RoundAndDistributeDelta(
            amount,
            CalculateByWeight(amount, eligible.Select(p => (p.UserId, Weight: p.Weight ?? p.ParticipationRatio))),
            currencyScale);
    }

    private static List<SplitShare> CalculateCustom(decimal amount, IReadOnlyCollection<SplitParticipantInput> participants)
    {
        var shares = participants
            .Select(p => new SplitShare(p.UserId, p.Amount ?? 0m))
            .ToList();

        if (Math.Abs(shares.Sum(s => s.Amount) - amount) > 0.0001m)
        {
            throw new DomainException("Custom split amounts must equal the total amount.", "CUSTOM_SPLIT_TOTAL_MISMATCH");
        }

        return shares;
    }

    private static List<SplitShare> CalculatePercentage(decimal amount, IReadOnlyCollection<SplitParticipantInput> participants)
    {
        var totalPercentage = participants.Sum(p => p.Percentage ?? 0m);
        if (Math.Abs(totalPercentage - 100m) > 0.0001m)
        {
            throw new DomainException("Percentage split must total 100.", "PERCENTAGE_SPLIT_TOTAL_MISMATCH");
        }

        return participants
            .Select(p => new SplitShare(p.UserId, amount * (p.Percentage ?? 0m) / 100m))
            .ToList();
    }

    private static List<SplitShare> CalculateByWeight(decimal amount, IEnumerable<(Guid UserId, decimal Weight)> inputs)
    {
        var weighted = inputs
            .Where(p => p.Weight > 0)
            .ToList();

        if (weighted.Count == 0)
        {
            throw new DomainException("Total split weight must be positive.", "INVALID_SPLIT_WEIGHT");
        }

        var totalWeight = weighted.Sum(p => p.Weight);
        return weighted
            .Select(p => new SplitShare(p.UserId, amount * p.Weight / totalWeight))
            .ToList();
    }

    private static SplitCalculationResult RoundAndDistributeDelta(
        decimal amount,
        List<SplitShare> rawShares,
        int currencyScale)
    {
        var rounded = rawShares
            .Select(s => new SplitShare(s.UserId, Math.Round(s.Amount, currencyScale, MidpointRounding.AwayFromZero)))
            .ToList();

        var roundedTotal = rounded.Sum(s => s.Amount);
        var delta = Math.Round(amount - roundedTotal, currencyScale, MidpointRounding.AwayFromZero);

        if (delta != 0m && rounded.Count > 0)
        {
            var target = rounded
                .Select((share, index) => new { share, index })
                .OrderByDescending(x => x.share.Amount)
                .First();

            rounded[target.index] = target.share with { Amount = target.share.Amount + delta };
        }

        return new SplitCalculationResult(rounded, delta);
    }
}
