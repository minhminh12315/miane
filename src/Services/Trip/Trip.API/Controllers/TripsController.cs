using MediatR;
using Microsoft.AspNetCore.Mvc;
using Trip.API.Features.CreateTrip;
using Trip.API.Features.GetTrip;
using Trip.API.Features.GetUserTrips;
using Trip.API.Features.JoinTrip;
using Trip.API.Features.LeaveTrip;
using Trip.API.Features.RemoveMember;
using Trip.API.Features.UpdateTrip;

namespace Trip.API.Controllers;

[ApiController]
[Route("trips")]
public class TripsController : ControllerBase
{
    private readonly IMediator _mediator;

    public TripsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id
            : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    private int GetUserTier() =>
        int.TryParse(Request.Headers["X-User-Tier"].FirstOrDefault(), out var tier)
            ? tier
            : 0;

    [HttpPost]
    public async Task<IActionResult> CreateTrip([FromBody] CreateTripRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(new CreateTripCommand(
            request.Name,
            request.Description,
            request.BaseCurrency ?? "VND",
            request.Destination,
            request.PlaceId,
            request.FormattedAddress,
            request.DestinationCity,
            request.DestinationProvince,
            request.DestinationCountry,
            request.PlaceTypes,
            request.PlaceMetadataJson,
            request.Latitude,
            request.Longitude,
            request.StartDate,
            request.EndDate,
            request.CoverImageUrl,
            request.CoverImagePrompt,
            request.CoverImageLandmark,
            GetUserId(),
            GetUserTier()), ct);

        return Created($"/trips/{result.TripId}", result);
    }

    [HttpPost("join")]
    public async Task<IActionResult> JoinTrip([FromBody] JoinTripRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(new JoinTripCommand(
            request.InviteCode,
            GetUserId(),
            GetUserTier(),
            request.NickName), ct);

        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetTrip(Guid id, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetTripQuery(id, GetUserId()), ct);
        return Ok(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetUserTrips(CancellationToken ct)
    {
        var result = await _mediator.Send(new GetUserTripsQuery(GetUserId()), ct);
        return Ok(result);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateTrip(Guid id, [FromBody] UpdateTripRequest request, CancellationToken ct)
    {
        await _mediator.Send(new UpdateTripCommand(
            id,
            GetUserId(),
            request.Name,
            request.Description,
            request.Status,
            request.StartDate,
            request.EndDate), ct);

        return NoContent();
    }

    [HttpDelete("{id:guid}/members/{userId:guid}")]
    public async Task<IActionResult> RemoveMember(Guid id, Guid userId, CancellationToken ct)
    {
        await _mediator.Send(new RemoveMemberCommand(id, userId, GetUserId()), ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/leave")]
    public async Task<IActionResult> LeaveTrip(Guid id, CancellationToken ct)
    {
        await _mediator.Send(new LeaveTripCommand(id, GetUserId()), ct);
        return NoContent();
    }
}

// Request DTOs
public sealed record CreateTripRequest(
    string Name,
    string? Description,
    string? BaseCurrency,
    string? Destination,
    string? PlaceId,
    string? FormattedAddress,
    string? DestinationCity,
    string? DestinationProvince,
    string? DestinationCountry,
    IReadOnlyCollection<string>? PlaceTypes,
    string? PlaceMetadataJson,
    double? Latitude,
    double? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? CoverImageUrl,
    string? CoverImagePrompt,
    string? CoverImageLandmark);
public sealed record JoinTripRequest(string InviteCode, string? NickName);
public sealed record UpdateTripRequest(
    string? Name,
    string? Description,
    Trip.API.Domain.Enums.TripStatus? Status,
    DateTime? StartDate = null,
    DateTime? EndDate = null);
