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
    List<ExpenseSplitDto> Splits,
    string? Title = null,
    string? Category = null,
    DateTime? PaidAt = null,
    List<ExpensePaymentSourceDto>? PaymentSources = null) : ICommand<CreateExpenseResult>;

public sealed record ExpenseSplitDto(Guid UserId, decimal? Amount, decimal? Percentage);

public sealed record ExpensePaymentSourceDto(
    Domain.Enums.ExpensePaymentSourceType SourceType,
    Guid? TripWalletId,
    Guid? UserId,
    Guid? PaymentId,
    decimal Amount);

public sealed record CreateExpenseResult(Guid ExpenseId, decimal ConvertedAmount, string BaseCurrency);
