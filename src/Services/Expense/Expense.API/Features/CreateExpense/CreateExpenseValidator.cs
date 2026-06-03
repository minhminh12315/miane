using FluentValidation;
using Expense.API.Domain.Enums;

namespace Expense.API.Features.CreateExpense;

public sealed class CreateExpenseValidator : AbstractValidator<CreateExpenseCommand>
{
    public CreateExpenseValidator()
    {
        RuleFor(x => x.TripId).NotEmpty();
        RuleFor(x => x.Description).NotEmpty().MaximumLength(500);
        RuleFor(x => x.Amount).GreaterThan(0).WithMessage("Amount must be positive.");
        RuleFor(x => x.Currency).NotEmpty().Length(3);
        RuleFor(x => x.TripBaseCurrency).NotEmpty().Length(3);
        RuleFor(x => x.PaidByUserId).NotEmpty();

        RuleFor(x => x.Splits)
            .NotEmpty().WithMessage("At least one split entry is required.")
            .When(x => x.SplitType != SplitType.TripPool);

        RuleFor(x => x.Splits)
            .Must(splits => splits.All(s => s.UserId != Guid.Empty))
            .WithMessage("All split entries must have a valid UserId.")
            .When(x => x.Splits.Count > 0);
    }
}
