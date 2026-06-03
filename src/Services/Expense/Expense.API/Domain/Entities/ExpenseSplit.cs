using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

public class ExpenseSplit : BaseEntity
{
    public Guid ExpenseId { get; set; }
    public Guid UserId { get; set; }

    /// <summary>
    /// The share amount this user owes (in trip base currency).
    /// </summary>
    public decimal Amount { get; set; }

    public bool IsPaid { get; set; }

    // Navigation
    public ExpenseEntity Expense { get; set; } = null!;
}
