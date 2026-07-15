using FluentValidation;

namespace Trip.API.Features.JoinTrip;

public sealed class JoinTripValidator : AbstractValidator<JoinTripCommand>
{
    public JoinTripValidator()
    {
        RuleFor(x => x.InviteCode)
            .NotEmpty().WithMessage("Vui lòng nhập mã mời.")
            .Length(8).WithMessage("Mã mời phải gồm đúng 8 ký tự.");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("Thiếu thông tin người dùng.");

        RuleFor(x => x.NickName)
            .MaximumLength(100).WithMessage("Biệt danh không được vượt quá 100 ký tự.")
            .When(x => x.NickName is not null);
    }
}
