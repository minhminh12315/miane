using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class FundRequest : AggregateRoot
{
    public Guid TripWalletId { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal TargetAmount { get; set; }
    public string Currency { get; set; } = "VND";
    public FundAllocationType AllocationType { get; set; } = FundAllocationType.Equal;
    public DateTime? DueAt { get; set; }
    public FundRequestStatus Status { get; set; } = FundRequestStatus.Draft;
    public Guid CreatedByUserId { get; set; }
    public string? Note { get; set; }

    public TripWallet TripWallet { get; set; } = null!;
}
