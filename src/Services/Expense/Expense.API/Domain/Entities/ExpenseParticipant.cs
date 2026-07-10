using BuildingBlocks.Domain;

namespace Expense.API.Domain.Entities;

public class ExpenseParticipant : BaseEntity
{
    public Guid ExpenseId { get; set; }
    public Guid UserId { get; set; }
    public decimal ShareAmount { get; set; }
    public decimal? SharePercent { get; set; }
    public decimal? Weight { get; set; }
    public string ParticipantType { get; set; } = "adult";
    public decimal ParticipationRatio { get; set; } = 1;
    public bool IsExcluded { get; set; }
    public string? Reason { get; set; }

    public ExpenseEntity Expense { get; set; } = null!;
}
