using FluentValidation;
using Trip.API.Data.Repositories;

namespace Trip.API.Features.CreateTrip;

public sealed class CreateTripValidator : AbstractValidator<CreateTripCommand>
{
    public CreateTripValidator(ITripRepository tripRepository)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Vui lòng nhập tên chuyến đi.")
            .MaximumLength(200).WithMessage("Tên chuyến đi không được vượt quá 200 ký tự.");

        RuleFor(x => x.BaseCurrency)
            .NotEmpty().WithMessage("Vui lòng chọn đơn vị tiền tệ.")
            .Length(3).WithMessage("Mã tiền tệ phải gồm đúng 3 ký tự (ví dụ: VND, USD).");

        RuleFor(x => x.Destination)
            .MaximumLength(240).WithMessage("Điểm đến không được vượt quá 240 ký tự.");

        RuleFor(x => x.PlaceId)
            .MaximumLength(256).WithMessage("Mã địa điểm không được vượt quá 256 ký tự.");

        RuleFor(x => x.FormattedAddress)
            .MaximumLength(500).WithMessage("Địa chỉ không được vượt quá 500 ký tự.");

        RuleFor(x => x.DestinationCity)
            .MaximumLength(160).WithMessage("Tên thành phố không được vượt quá 160 ký tự.");

        RuleFor(x => x.DestinationProvince)
            .MaximumLength(160).WithMessage("Tên tỉnh/thành không được vượt quá 160 ký tự.");

        RuleFor(x => x.DestinationCountry)
            .MaximumLength(120).WithMessage("Tên quốc gia không được vượt quá 120 ký tự.");

        RuleFor(x => x.PlaceMetadataJson)
            .MaximumLength(2000).WithMessage("Dữ liệu địa điểm không được vượt quá 2000 ký tự.");

        RuleFor(x => x.CoverImageUrl)
            .MaximumLength(1000).WithMessage("Đường dẫn ảnh bìa không được vượt quá 1000 ký tự.");

        RuleFor(x => x.CoverImagePrompt)
            .MaximumLength(1000).WithMessage("Mô tả ảnh bìa không được vượt quá 1000 ký tự.");

        RuleFor(x => x.CoverImageLandmark)
            .MaximumLength(160).WithMessage("Tên địa danh trong ảnh bìa không được vượt quá 160 ký tự.");

        RuleFor(x => x)
            .Must(x => !x.StartDate.HasValue || !x.EndDate.HasValue || x.EndDate.Value.Date >= x.StartDate.Value.Date)
            .WithMessage("Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("Thiếu thông tin người dùng.");

        // MIANE Basic tier: max 2 active trips
        RuleFor(x => x)
            .MustAsync(async (cmd, cancellation) =>
            {
                if (cmd.UserTier >= 1) return true; // Pro users bypass
                var activeTripCount = await tripRepository.GetActiveTripCountByUserAsync(cmd.UserId, cancellation);
                return activeTripCount < 2;
            })
            .WithMessage("Gói MIANE Basic chỉ cho phép tối đa 2 chuyến đi. Nâng cấp lên MIANE Pro để tạo không giới hạn.")
            .WithErrorCode("TIER_LIMIT_EXCEEDED");
    }
}
