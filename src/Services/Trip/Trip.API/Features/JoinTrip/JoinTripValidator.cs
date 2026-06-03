using FluentValidation;

namespace Trip.API.Features.JoinTrip;

public sealed class JoinTripValidator : AbstractValidator<JoinTripCommand>
{
    public JoinTripValidator()
    {
        RuleFor(x => x.InviteCode)
            .NotEmpty().WithMessage("Invite code is required.")
            .Length(8).WithMessage("Invite code must be exactly 8 characters.");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required.");

        RuleFor(x => x.NickName)
            .MaximumLength(100).WithMessage("Nick name cannot exceed 100 characters.")
            .When(x => x.NickName is not null);
    }
}
