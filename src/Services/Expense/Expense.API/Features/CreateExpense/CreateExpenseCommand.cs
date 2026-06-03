using BuildingBlocks.CQRS;
using Expense.API.Domain.Enums;

namespace Expense.API.Features.CreateExpense;

public sealed record CreateExpenseCommand(
    Guid TripId,
    string Description,
    decimal Amount,
    string Currency,
    string TripBaseCurrency,
    Guid PaidByUserId,
    SplitType SplitType,
    List<ExpenseSplitDto> Splits) : ICommand<CreateExpenseResult>;

public sealed record ExpenseSplitDto(Guid UserId, decimal? Amount, decimal? Percentage);

public sealed record CreateExpenseResult(Guid ExpenseId, decimal ConvertedAmount, string BaseCurrency);
