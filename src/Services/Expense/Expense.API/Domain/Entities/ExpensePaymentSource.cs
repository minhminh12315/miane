using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class ExpensePaymentSource : BaseEntity
{
    public Guid ExpenseId { get; set; }
    public ExpensePaymentSourceType SourceType { get; set; }
    public Guid? TripWalletId { get; set; }
    public Guid? UserId { get; set; }
    public Guid? PaymentId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public Guid? WalletTransactionId { get; set; }

    public ExpenseEntity Expense { get; set; } = null!;
}
