using System.Text.Json;
using BuildingBlocks.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Trip.API.Data;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;

namespace Trip.API.Controllers;

[ApiController]
[Route("trips/{tripId:guid}/files")]
public class TripFilesController : ControllerBase
{
    private const long MaxUploadBytes = 25 * 1024 * 1024;
    private const string ManageFilesPermission = "manage_files";
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
        ".heic",
        ".pdf",
        ".txt",
        ".md",
        ".rtf",
        ".doc",
        ".docx",
        ".xls",
        ".xlsx",
        ".csv",
        ".ppt",
        ".pptx"
    };

    private readonly TripDbContext _db;
    private readonly IWebHostEnvironment _environment;

    public TripFilesController(TripDbContext db, IWebHostEnvironment environment)
    {
        _db = db;
        _environment = environment;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id
            : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpGet]
    public async Task<IActionResult> GetTripFiles(Guid tripId, [FromQuery] string? folder, CancellationToken ct)
    {
        await EnsureTripMemberAsync(tripId, GetUserId(), ct);

        var query = _db.TripFiles
            .AsNoTracking()
            .Where(file => file.TripId == tripId);

        if (!string.IsNullOrWhiteSpace(folder))
        {
            var normalizedFolder = NormalizeFolder(folder);
            query = query.Where(file => file.Folder == normalizedFolder);
        }

        var files = await query
            .OrderBy(file => file.Folder)
            .ThenByDescending(file => file.CreatedAt)
            .Select(file => ToResponse(file))
            .ToListAsync(ct);

        return Ok(files);
    }

    [HttpPost]
    public async Task<IActionResult> AddTripFile(Guid tripId, [FromBody] CreateTripFileRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        await EnsureTripMemberAsync(tripId, userId, ct);

        var fileName = TrimToMax(request.FileName, 260);
        var fileUrl = TrimToMax(request.FileUrl, 1000);
        if (string.IsNullOrWhiteSpace(fileName))
        {
            return BadRequest(new { message = "File name is required." });
        }

        if (string.IsNullOrWhiteSpace(fileUrl) ||
            !Uri.TryCreate(fileUrl, UriKind.Absolute, out _))
        {
            return BadRequest(new { message = "A valid file URL is required." });
        }

        if (request.FileSizeBytes is < 0)
        {
            return BadRequest(new { message = "File size cannot be negative." });
        }

        var file = new TripFile
        {
            TripId = tripId,
            Folder = NormalizeFolder(request.Folder),
            FileName = fileName,
            FileUrl = fileUrl,
            ContentType = TrimToMax(request.ContentType, 120),
            FileSizeBytes = request.FileSizeBytes,
            UploadedByUserId = userId,
            Tags = SerializeStringArray(request.Tags),
            Permissions = "[]"
        };

        await _db.TripFiles.AddAsync(file, ct);
        await _db.SaveChangesAsync(ct);

        return Created($"/trips/{tripId}/files/{file.Id}", ToResponse(file));
    }

    [HttpPost("upload")]
    [RequestSizeLimit(MaxUploadBytes)]
    public async Task<IActionResult> UploadTripFile(
        Guid tripId,
        [FromForm] IFormFile? file,
        [FromForm] string? folder,
        [FromForm] string? tags,
        CancellationToken ct)
    {
        var userId = GetUserId();
        await EnsureTripMemberAsync(tripId, userId, ct);

        if (file is null || file.Length <= 0)
        {
            return BadRequest(new { message = "File is required." });
        }

        if (file.Length > MaxUploadBytes)
        {
            return BadRequest(new { message = "File size cannot exceed 25 MB." });
        }

        var originalFileName = Path.GetFileName(file.FileName);
        var extension = Path.GetExtension(originalFileName);
        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.Contains(extension))
        {
            return BadRequest(new { message = "This file type is not supported." });
        }

        var storageName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var uploadDirectory = GetTripUploadDirectory(tripId);
        Directory.CreateDirectory(uploadDirectory);

        var absolutePath = Path.Combine(uploadDirectory, storageName);
        await using (var stream = System.IO.File.Create(absolutePath))
        {
            await file.CopyToAsync(stream, ct);
        }

        var tripFile = new TripFile
        {
            TripId = tripId,
            Folder = NormalizeFolder(folder),
            FileName = TrimToMax(originalFileName, 260) ?? storageName,
            FileUrl = BuildContentUrl(tripId, storageName),
            ContentType = NormalizeContentType(file.ContentType, extension),
            FileSizeBytes = file.Length,
            UploadedByUserId = userId,
            Tags = SerializeCsvTags(tags),
            Permissions = "[]"
        };

        await _db.TripFiles.AddAsync(tripFile, ct);
        await _db.SaveChangesAsync(ct);

        return Created($"/trips/{tripId}/files/{tripFile.Id}", ToResponse(tripFile));
    }

    [HttpPost("notes")]
    public async Task<IActionResult> AddTripNote(Guid tripId, [FromBody] CreateTripNoteRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        await EnsureTripMemberAsync(tripId, userId, ct);

        var title = TrimToMax(request.Title, 220);
        var content = request.Content?.Trim();
        if (string.IsNullOrWhiteSpace(title))
        {
            return BadRequest(new { message = "Note title is required." });
        }

        if (string.IsNullOrWhiteSpace(content))
        {
            return BadRequest(new { message = "Note content is required." });
        }

        var storageName = $"{Guid.NewGuid():N}.txt";
        var uploadDirectory = GetTripUploadDirectory(tripId);
        Directory.CreateDirectory(uploadDirectory);

        var absolutePath = Path.Combine(uploadDirectory, storageName);
        await System.IO.File.WriteAllTextAsync(absolutePath, content, ct);
        var fileInfo = new FileInfo(absolutePath);

        var tripFile = new TripFile
        {
            TripId = tripId,
            Folder = NormalizeFolder(request.Folder ?? "Ghi chú"),
            FileName = $"{title}.txt",
            FileUrl = BuildContentUrl(tripId, storageName),
            ContentType = "text/plain",
            FileSizeBytes = fileInfo.Length,
            UploadedByUserId = userId,
            Tags = SerializeStringArray(request.Tags),
            Permissions = "[]"
        };

        await _db.TripFiles.AddAsync(tripFile, ct);
        await _db.SaveChangesAsync(ct);

        return Created($"/trips/{tripId}/files/{tripFile.Id}", ToResponse(tripFile));
    }

    [HttpGet("content/{storageName}")]
    public async Task<IActionResult> GetTripFileContent(Guid tripId, string storageName, CancellationToken ct)
    {
        await EnsureTripMemberAsync(tripId, GetUserId(), ct);

        var safeStorageName = Path.GetFileName(storageName);
        if (safeStorageName != storageName)
        {
            return BadRequest(new { message = "Invalid file name." });
        }

        var file = await _db.TripFiles
            .AsNoTracking()
            .FirstOrDefaultAsync(item =>
                item.TripId == tripId &&
                item.FileUrl.EndsWith($"/{safeStorageName}"), ct)
            ?? throw new NotFoundException("Trip file", storageName);

        var absolutePath = Path.Combine(GetTripUploadDirectory(tripId), safeStorageName);
        if (!System.IO.File.Exists(absolutePath))
        {
            throw new NotFoundException("Trip file content", storageName);
        }

        return PhysicalFile(
            absolutePath,
            file.ContentType ?? "application/octet-stream",
            enableRangeProcessing: true);
    }

    [HttpDelete("{fileId:guid}")]
    public async Task<IActionResult> DeleteTripFile(Guid tripId, Guid fileId, CancellationToken ct)
    {
        var userId = GetUserId();
        var member = await EnsureTripMemberAsync(tripId, userId, ct);

        var file = await _db.TripFiles
            .FirstOrDefaultAsync(item => item.TripId == tripId && item.Id == fileId, ct)
            ?? throw new NotFoundException("Trip file", fileId);

        if (file.UploadedByUserId != userId && !CanManageFiles(member))
        {
            throw new ForbiddenAccessException("Only the uploader or a file manager can remove this trip file.");
        }

        DeleteStoredContentIfLocal(tripId, file.FileUrl);
        _db.TripFiles.Remove(file);
        await _db.SaveChangesAsync(ct);

        return NoContent();
    }

    private async Task<TripMember> EnsureTripMemberAsync(Guid tripId, Guid userId, CancellationToken ct)
    {
        var tripExists = await _db.Trips
            .AsNoTracking()
            .AnyAsync(trip => trip.Id == tripId, ct);
        if (!tripExists)
        {
            throw new NotFoundException("Trip", tripId);
        }

        return await _db.TripMembers
            .Include(member => member.CustomRole)
            .FirstOrDefaultAsync(member => member.TripId == tripId && member.UserId == userId, ct)
            ?? throw new ForbiddenAccessException("You are not a member of this trip.");
    }

    private static bool CanManageFiles(TripMember member)
    {
        if (member.Role is MemberRole.Owner or MemberRole.Admin)
        {
            return true;
        }

        return DeserializeStringArray(member.CustomRole?.Permissions)
            .Contains(ManageFilesPermission, StringComparer.OrdinalIgnoreCase);
    }

    private static TripFileResponse ToResponse(TripFile file) => new(
        file.Id,
        file.TripId,
        file.Folder,
        file.FileName,
        file.FileUrl,
        file.ContentType,
        file.FileSizeBytes,
        file.UploadedByUserId,
        DeserializeStringArray(file.Tags),
        file.CreatedAt);

    private static string NormalizeFolder(string? folder) =>
        TrimToMax(folder, 160) ?? "General";

    private static string? TrimToMax(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim();
        return trimmed.Length <= maxLength ? trimmed : trimmed[..maxLength];
    }

    private static string SerializeStringArray(IReadOnlyCollection<string>? values)
    {
        var normalized = (values ?? Array.Empty<string>())
            .Select(value => TrimToMax(value, 40))
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(12)
            .ToList();

        return JsonSerializer.Serialize(normalized);
    }

    private static string SerializeCsvTags(string? value)
    {
        var tags = string.IsNullOrWhiteSpace(value)
            ? Array.Empty<string>()
            : value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        return SerializeStringArray(tags);
    }

    private string GetTripUploadDirectory(Guid tripId) =>
        Path.Combine(_environment.ContentRootPath, "uploads", "trip-files", tripId.ToString("N"));

    private static string BuildContentUrl(Guid tripId, string storageName) =>
        $"/trips/{tripId}/files/content/{storageName}";

    private void DeleteStoredContentIfLocal(Guid tripId, string fileUrl)
    {
        var marker = $"/trips/{tripId}/files/content/";
        var index = fileUrl.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
        if (index < 0) return;

        var storageName = fileUrl[(index + marker.Length)..];
        storageName = Path.GetFileName(storageName);
        if (string.IsNullOrWhiteSpace(storageName)) return;

        var absolutePath = Path.Combine(GetTripUploadDirectory(tripId), storageName);
        if (System.IO.File.Exists(absolutePath))
        {
            System.IO.File.Delete(absolutePath);
        }
    }

    private static string GuessContentType(string extension) =>
        extension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".heic" => "image/heic",
            ".pdf" => "application/pdf",
            ".txt" => "text/plain",
            ".md" => "text/markdown",
            ".rtf" => "application/rtf",
            ".doc" => "application/msword",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".xls" => "application/vnd.ms-excel",
            ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ".csv" => "text/csv",
            ".ppt" => "application/vnd.ms-powerpoint",
            ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            _ => "application/octet-stream"
        };

    private static string NormalizeContentType(string? contentType, string extension)
    {
        var trimmed = TrimToMax(contentType, 120);
        if (string.IsNullOrWhiteSpace(trimmed) ||
            trimmed.Equals("application/octet-stream", StringComparison.OrdinalIgnoreCase))
        {
            return GuessContentType(extension);
        }

        return trimmed;
    }

    private static List<string> DeserializeStringArray(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
        }
        catch (JsonException)
        {
            return new List<string>();
        }
    }
}

public sealed record CreateTripFileRequest(
    string FileName,
    string FileUrl,
    string? Folder,
    string? ContentType,
    long? FileSizeBytes,
    IReadOnlyCollection<string>? Tags);

public sealed record CreateTripNoteRequest(
    string Title,
    string Content,
    string? Folder,
    IReadOnlyCollection<string>? Tags);

public sealed record TripFileResponse(
    Guid Id,
    Guid TripId,
    string Folder,
    string FileName,
    string FileUrl,
    string? ContentType,
    long? FileSizeBytes,
    Guid UploadedByUserId,
    List<string> Tags,
    DateTime CreatedAt);
