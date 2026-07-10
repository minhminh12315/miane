using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class FundContribution : BaseEntity
{
    public Guid? FundRequestId { get; set; }
    public Guid TripWalletId { get; set; }
    public Guid UserId { get; set; }
    public decimal ExpectedAmount { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public Guid? PaymentId { get; set; }
    public Guid? WalletTransactionId { get; set; }
    public FundContributionStatus Status { get; set; } = FundContributionStatus.Pending;
    public Guid? ConfirmedByUserId { get; set; }
    public DateTime? ConfirmedAt { get; set; }

    public FundRequest? FundRequest { get; set; }
    public TripWallet TripWallet { get; set; } = null!;
}
