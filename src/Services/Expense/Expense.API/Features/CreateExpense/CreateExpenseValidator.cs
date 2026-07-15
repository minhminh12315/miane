using FluentValidation;
using Expense.API.Domain.Enums;

namespace Expense.API.Features.CreateExpense;

public sealed class CreateExpenseValidator : AbstractValidator<CreateExpenseCommand>
{
    public CreateExpenseValidator()
    {
        RuleFor(x => x.TripId).NotEmpty();
        RuleFor(x => x.Description).NotEmpty().MaximumLength(500);
        RuleFor(x => x.Amount).GreaterThan(0).WithMessage("Số tiền phải lớn hơn 0.");
        RuleFor(x => x.Currency).NotEmpty().Length(3);
        RuleFor(x => x.TripBaseCurrency).NotEmpty().Length(3);
        RuleFor(x => x.PaidByUserId).NotEmpty();

        RuleFor(x => x.Splits)
            .NotEmpty().WithMessage("Cần ít nhất một khoản chia.")
            .When(x => x.SplitType != SplitType.TripPool);

        RuleFor(x => x.Splits)
            .Must(splits => splits.All(s => s.UserId != Guid.Empty))
            .WithMessage("Tất cả khoản chia phải có người dùng hợp lệ.")
            .When(x => x.Splits.Count > 0);
    }
}
