using BuildingBlocks.CQRS;
using BuildingBlocks.Exceptions;
using Microsoft.EntityFrameworkCore;
using Trip.API.Data;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;

namespace Trip.API.Features.TripLegs;

public sealed record TripLegDto(
    Guid Id,
    int Order,
    string Name,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Notes);

// ── Query: list legs ────────────────────────────────────────────────────────
public sealed record GetTripLegsQuery(Guid TripId) : IQuery<List<TripLegDto>>;

public sealed class GetTripLegsHandler : IQueryHandler<GetTripLegsQuery, List<TripLegDto>>
{
    private readonly TripDbContext _db;
    public GetTripLegsHandler(TripDbContext db) => _db = db;

    public async Task<List<TripLegDto>> Handle(GetTripLegsQuery request, CancellationToken ct)
    {
        return await _db.TripLegs
            .Where(l => l.TripId == request.TripId)
            .OrderBy(l => l.Order)
            .Select(l => new TripLegDto(
                l.Id, l.Order, l.Name, l.DestinationCity, l.DestinationCountry,
                l.Latitude, l.Longitude, l.StartDate, l.EndDate, l.Notes))
            .ToListAsync(ct);
    }
}

// ── Command: add a leg ──────────────────────────────────────────────────────
public sealed record AddTripLegCommand(
    Guid TripId,
    Guid UserId,
    string Name,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Notes) : ICommand<Guid>;

public sealed class AddTripLegHandler : ICommandHandler<AddTripLegCommand, Guid>
{
    private readonly TripDbContext _db;
    public AddTripLegHandler(TripDbContext db) => _db = db;

    public async Task<Guid> Handle(AddTripLegCommand request, CancellationToken ct)
    {
        await TripLegAuth.EnsureCanEditAsync(_db, request.TripId, request.UserId, ct);

        var nextOrder = await _db.TripLegs
            .Where(l => l.TripId == request.TripId)
            .Select(l => (int?)l.Order)
            .MaxAsync(ct) ?? -1;

        var leg = new TripLeg
        {
            TripId = request.TripId,
            Order = nextOrder + 1,
            Name = request.Name,
            DestinationCity = request.DestinationCity,
            DestinationCountry = request.DestinationCountry,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            Notes = request.Notes
        };
        ValidateDates(leg);

        await _db.TripLegs.AddAsync(leg, ct);
        await _db.SaveChangesAsync(ct);
        return leg.Id;
    }

    internal static void ValidateDates(TripLeg leg)
    {
        if (leg.StartDate.HasValue && leg.EndDate.HasValue &&
            leg.EndDate.Value < leg.StartDate.Value)
        {
            throw new DomainException(
                "Ngày kết thúc chặng không được trước ngày bắt đầu.",
                "INVALID_LEG_DATE_RANGE");
        }
    }
}

// ── Command: update a leg ───────────────────────────────────────────────────
public sealed record UpdateTripLegCommand(
    Guid TripId,
    Guid LegId,
    Guid UserId,
    int? Order,
    string? Name,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Notes) : ICommand;

public sealed class UpdateTripLegHandler : ICommandHandler<UpdateTripLegCommand>
{
    private readonly TripDbContext _db;
    public UpdateTripLegHandler(TripDbContext db) => _db = db;

    public async Task<MediatR.Unit> Handle(UpdateTripLegCommand request, CancellationToken ct)
    {
        await TripLegAuth.EnsureCanEditAsync(_db, request.TripId, request.UserId, ct);

        var leg = await _db.TripLegs
            .FirstOrDefaultAsync(l => l.Id == request.LegId && l.TripId == request.TripId, ct)
            ?? throw new NotFoundException("chặng đi", request.LegId);

        if (request.Order.HasValue) leg.Order = request.Order.Value;
        if (!string.IsNullOrWhiteSpace(request.Name)) leg.Name = request.Name;
        if (request.DestinationCity is not null) leg.DestinationCity = request.DestinationCity;
        if (request.DestinationCountry is not null) leg.DestinationCountry = request.DestinationCountry;
        if (request.Latitude.HasValue) leg.Latitude = request.Latitude;
        if (request.Longitude.HasValue) leg.Longitude = request.Longitude;
        if (request.StartDate.HasValue) leg.StartDate = request.StartDate;
        if (request.EndDate.HasValue) leg.EndDate = request.EndDate;
        if (request.Notes is not null) leg.Notes = request.Notes;

        AddTripLegHandler.ValidateDates(leg);

        await _db.SaveChangesAsync(ct);
        return MediatR.Unit.Value;
    }
}

// ── Command: delete a leg ───────────────────────────────────────────────────
public sealed record DeleteTripLegCommand(Guid TripId, Guid LegId, Guid UserId) : ICommand;

public sealed class DeleteTripLegHandler : ICommandHandler<DeleteTripLegCommand>
{
    private readonly TripDbContext _db;
    public DeleteTripLegHandler(TripDbContext db) => _db = db;

    public async Task<MediatR.Unit> Handle(DeleteTripLegCommand request, CancellationToken ct)
    {
        await TripLegAuth.EnsureCanEditAsync(_db, request.TripId, request.UserId, ct);

        var leg = await _db.TripLegs
            .FirstOrDefaultAsync(l => l.Id == request.LegId && l.TripId == request.TripId, ct)
            ?? throw new NotFoundException("chặng đi", request.LegId);

        _db.TripLegs.Remove(leg);
        await _db.SaveChangesAsync(ct);
        return MediatR.Unit.Value;
    }
}

internal static class TripLegAuth
{
    /// Only the trip owner or an admin member may add/update/delete legs.
    public static async Task EnsureCanEditAsync(
        TripDbContext db, Guid tripId, Guid userId, CancellationToken ct)
    {
        var member = await db.TripMembers
            .FirstOrDefaultAsync(m => m.TripId == tripId && m.UserId == userId, ct);
        if (member is null || (member.Role != MemberRole.Owner && member.Role != MemberRole.Admin))
        {
            throw new ForbiddenAccessException(
                "Chỉ chủ chuyến đi hoặc quản trị viên mới có thể quản lý chặng đi.");
        }

        var trip = await db.Trips
            .Where(t => t.Id == tripId)
            .Select(t => new { t.EndDate })
            .FirstOrDefaultAsync(ct)
            ?? throw new NotFoundException("chuyến đi", tripId);

        if (trip.EndDate.HasValue && trip.EndDate.Value.Date < DateTime.UtcNow.Date)
        {
            throw new DomainException(
                "Chuyến đi đã kết thúc nên không thể thay đổi chặng đi.",
                "TRIP_ALREADY_COMPLETED");
        }
    }
}
