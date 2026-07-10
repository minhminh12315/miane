using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

public class TransactionHistory : BaseEntity
{
    public Guid TripId { get; set; }
    public Guid ActorUserId { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public string Action { get; set; } = string.Empty;
    public decimal? Amount { get; set; }
    public string? Currency { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? MetadataJson { get; set; }
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
}
