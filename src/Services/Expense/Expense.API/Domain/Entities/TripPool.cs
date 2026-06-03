using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

/// <summary>
/// Represents a shared fund pool for a trip. Members contribute to this pool
/// and expenses can be deducted directly from it.
/// </summary>
public class TripPool : AggregateRoot
{
    public Guid TripId { get; set; }
    public decimal Balance { get; set; }
    public string Currency { get; set; } = "VND";

    // Navigation
    private readonly List<PoolContribution> _contributions = new();
    public IReadOnlyCollection<PoolContribution> Contributions => _contributions.AsReadOnly();

    public void AddContribution(PoolContribution contribution)
    {
        _contributions.Add(contribution);
        Balance += contribution.Amount;
    }

    public void Deduct(decimal amount)
    {
        if (amount > Balance)
        {
            throw new BuildingBlocks.Exceptions.DomainException(
                $"Insufficient pool balance. Available: {Balance:F2} {Currency}, Required: {amount:F2} {Currency}",
                "INSUFFICIENT_POOL_BALANCE");
        }
        Balance -= amount;
    }
}
