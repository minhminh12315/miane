using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

public class PoolContribution : BaseEntity
{
    public Guid TripPoolId { get; set; }
    public Guid UserId { get; set; }
    public decimal Amount { get; set; }
    public DateTime ContributedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public TripPool TripPool { get; set; } = null!;
}
