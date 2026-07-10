using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

public class ExpenseItem : BaseEntity
{
    public Guid ExpenseId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Quantity { get; set; } = 1;
    public decimal UnitAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public string? Category { get; set; }
    public string? AssignedUserIdsJson { get; set; }

    public ExpenseEntity Expense { get; set; } = null!;
}
