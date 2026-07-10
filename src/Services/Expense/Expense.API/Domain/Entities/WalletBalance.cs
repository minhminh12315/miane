using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

public class WalletBalance : BaseEntity
{
    public Guid TripWalletId { get; set; }
    public Guid UserId { get; set; }
    public decimal ContributedAmount { get; set; }
    public decimal ExpectedAmount { get; set; }
    public decimal PendingAmount { get; set; }
    public decimal RefundableAmount { get; set; }
    public DateTime LastCalculatedAt { get; set; } = DateTime.UtcNow;

    public TripWallet TripWallet { get; set; } = null!;
}
