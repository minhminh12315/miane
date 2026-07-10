using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class Settlement : AggregateRoot
{
    public Guid TripId { get; set; }
    public Guid? DebtId { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public decimal Amount { get; set; }
    public decimal PaidAmount { get; set; }
    public string Currency { get; set; } = "VND";
    public SettlementStatus Status { get; set; } = SettlementStatus.Open;
    public Guid? PaymentId { get; set; }
    public DateTime? SettledAt { get; set; }
    public Guid? SupersededBySettlementId { get; set; }
}
