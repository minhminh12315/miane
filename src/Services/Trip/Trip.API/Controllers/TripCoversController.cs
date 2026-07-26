using BuildingBlocks.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Trip.API.Data;
using Trip.API.Domain.Enums;

namespace Trip.API.Controllers;

[ApiController]
[Route("trips/{tripId:guid}/cover")]
public sealed class TripCoversController : ControllerBase
{
    private const long MaxCoverBytes = 8 * 1024 * 1024;
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
        ".heic"
    };

    private readonly TripDbContext _db;
    private readonly IWebHostEnvironment _environment;

    public TripCoversController(TripDbContext db, IWebHostEnvironment environment)
    {
        _db = db;
        _environment = environment;
    }

    [HttpPost]
    [RequestSizeLimit(MaxCoverBytes)]
    public async Task<IActionResult> Upload(
        Guid tripId,
        [FromForm] IFormFile? file,
        CancellationToken ct)
    {
        var userId = GetUserId();
        var trip = await _db.Trips
            .FirstOrDefaultAsync(item => item.Id == tripId, ct)
            ?? throw new NotFoundException("chuyến đi", tripId);

        var member = await _db.TripMembers
            .AsNoTracking()
            .FirstOrDefaultAsync(
                item => item.TripId == tripId && item.UserId == userId,
                ct)
            ?? throw new ForbiddenAccessException(
                "Bạn không phải là thành viên của chuyến đi này.");

        if (member.Role is not (MemberRole.Owner or MemberRole.Admin))
        {
            throw new ForbiddenAccessException(
                "Chỉ chủ chuyến đi hoặc quản trị viên mới có thể đổi ảnh bìa.");
        }

        if (file is null || file.Length <= 0)
        {
            return BadRequest(new { message = "Vui lòng chọn một ảnh bìa." });
        }

        if (file.Length > MaxCoverBytes)
        {
            return BadRequest(new
            {
                message = "Dung lượng ảnh bìa không được vượt quá 8 MB."
            });
        }

        var extension = Path.GetExtension(Path.GetFileName(file.FileName))
            .ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
        {
            return BadRequest(new
            {
                message = "Ảnh bìa phải có định dạng JPG, PNG, WEBP hoặc HEIC."
            });
        }

        await using var uploadStream = file.OpenReadStream();
        if (!BuildingBlocks.Validation.ImageMagicBytes.TryGetExtension(uploadStream, out var detectedExtension)
            || !AllowedExtensions.Contains(detectedExtension))
        {
            return BadRequest(new { message = "Nội dung tệp không phải ảnh hợp lệ." });
        }

        var storageName = $"{Guid.NewGuid():N}{detectedExtension}";
        var uploadDirectory = GetCoverDirectory(tripId);
        Directory.CreateDirectory(uploadDirectory);
        var absolutePath = Path.Combine(uploadDirectory, storageName);

        await using (var stream = System.IO.File.Create(absolutePath))
        {
            uploadStream.Position = 0;
            await uploadStream.CopyToAsync(stream, ct);
        }

        var previousCoverUrl = trip.CoverImageUrl;
        var coverImageUrl = $"/trips/{tripId}/cover/content/{storageName}";
        trip.CoverImageUrl = coverImageUrl;

        try
        {
            await _db.SaveChangesAsync(ct);
        }
        catch
        {
            System.IO.File.Delete(absolutePath);
            throw;
        }

        DeletePreviousLocalCover(tripId, previousCoverUrl);
        return Ok(new { coverImageUrl });
    }

    [HttpGet("content/{storageName}")]
    public IActionResult Content(Guid tripId, string storageName)
    {
        var safeStorageName = Path.GetFileName(storageName);
        if (safeStorageName != storageName)
        {
            return BadRequest(new { message = "Tên ảnh bìa không hợp lệ." });
        }

        var absolutePath = Path.Combine(GetCoverDirectory(tripId), safeStorageName);
        if (!System.IO.File.Exists(absolutePath))
        {
            throw new NotFoundException("ảnh bìa", storageName);
        }

        Response.Headers.CacheControl = "public,max-age=31536000,immutable";
        return PhysicalFile(
            absolutePath,
            ContentTypeFor(Path.GetExtension(safeStorageName)),
            enableRangeProcessing: true);
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id
            : throw new UnauthorizedAccessException(
                "Missing X-User-Id header.");

    private string GetCoverDirectory(Guid tripId) =>
        Path.Combine(
            _environment.ContentRootPath,
            "uploads",
            "trip-covers",
            tripId.ToString("N"));

    private void DeletePreviousLocalCover(Guid tripId, string? coverUrl)
    {
        var marker = $"/trips/{tripId}/cover/content/";
        if (string.IsNullOrWhiteSpace(coverUrl) ||
            !coverUrl.StartsWith(marker, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var storageName = Path.GetFileName(coverUrl[marker.Length..]);
        if (string.IsNullOrWhiteSpace(storageName)) return;

        var absolutePath = Path.Combine(GetCoverDirectory(tripId), storageName);
        if (System.IO.File.Exists(absolutePath))
        {
            System.IO.File.Delete(absolutePath);
        }
    }

    private static string ContentTypeFor(string extension) =>
        extension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".heic" => "image/heic",
            _ => "application/octet-stream"
        };
}
