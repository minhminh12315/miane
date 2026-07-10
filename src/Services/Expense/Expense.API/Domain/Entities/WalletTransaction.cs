using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class WalletTransaction : BaseEntity
{
    public Guid TripWalletId { get; set; }
    public string TransactionNo { get; set; } = string.Empty;
    public WalletTransactionType Type { get; set; }
    public TransactionDirection Direction { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public decimal? BalanceAfter { get; set; }
    public Guid ActorUserId { get; set; }
    public Guid? CounterpartyUserId { get; set; }
    public Guid? ExpenseId { get; set; }
    public Guid? FundContributionId { get; set; }
    public Guid? PaymentId { get; set; }
    public Guid? ReversesTransactionId { get; set; }
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
    public WalletTransactionStatus Status { get; set; } = WalletTransactionStatus.Pending;
    public string? MetadataJson { get; set; }

    public TripWallet TripWallet { get; set; } = null!;
}
