using FluentValidation;
using Trip.API.Data.Repositories;

namespace Trip.API.Features.CreateTrip;

public sealed class CreateTripValidator : AbstractValidator<CreateTripCommand>
{
    public CreateTripValidator(ITripRepository tripRepository)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Trip name is required.")
            .MaximumLength(200).WithMessage("Trip name cannot exceed 200 characters.");

        RuleFor(x => x.BaseCurrency)
            .NotEmpty().WithMessage("Base currency is required.")
            .Length(3).WithMessage("Currency code must be exactly 3 characters (e.g., VND, USD).");

        RuleFor(x => x.Destination)
            .MaximumLength(240).WithMessage("Destination cannot exceed 240 characters.");

        RuleFor(x => x.DestinationCity)
            .MaximumLength(160).WithMessage("Destination city cannot exceed 160 characters.");

        RuleFor(x => x.DestinationCountry)
            .MaximumLength(120).WithMessage("Destination country cannot exceed 120 characters.");

        RuleFor(x => x.CoverImageUrl)
            .MaximumLength(1000).WithMessage("Cover image URL cannot exceed 1000 characters.");

        RuleFor(x => x)
            .Must(x => !x.StartDate.HasValue || !x.EndDate.HasValue || x.EndDate.Value.Date >= x.StartDate.Value.Date)
            .WithMessage("Trip end date must be greater than or equal to start date.");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("User ID is required.");

        // MIANE Basic tier: max 2 active trips
        RuleFor(x => x)
            .MustAsync(async (cmd, cancellation) =>
            {
                if (cmd.UserTier >= 1) return true; // Pro users bypass
                var activeTripCount = await tripRepository.GetActiveTripCountByUserAsync(cmd.UserId, cancellation);
                return activeTripCount < 2;
            })
            .WithMessage("MIANE Basic users can only have 2 active trips. Upgrade to MIANE Pro for unlimited trips.")
            .WithErrorCode("TIER_LIMIT_EXCEEDED");
    }
}
