using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class Debt : BaseEntity
{
    public Guid TripId { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public DebtStatus Status { get; set; } = DebtStatus.Open;
    public Guid CalculationRunId { get; set; }
    public string? SourceHash { get; set; }
}
