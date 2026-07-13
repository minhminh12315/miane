using MediatR;
using Microsoft.AspNetCore.Mvc;
using Trip.API.Features.TripLegs;

namespace Trip.API.Controllers;

[ApiController]
[Route("trips/{tripId:guid}/legs")]
public class TripLegsController : ControllerBase
{
    private readonly IMediator _mediator;

    public TripLegsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id
            : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpGet]
    public async Task<IActionResult> GetLegs(Guid tripId, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetTripLegsQuery(tripId), ct);
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> AddLeg(
        Guid tripId, [FromBody] AddTripLegRequest request, CancellationToken ct)
    {
        var id = await _mediator.Send(new AddTripLegCommand(
            tripId,
            GetUserId(),
            request.Name,
            request.DestinationCity,
            request.DestinationCountry,
            request.Latitude,
            request.Longitude,
            request.StartDate,
            request.EndDate,
            request.Notes), ct);

        return Created($"/trips/{tripId}/legs/{id}", new { id });
    }

    [HttpPut("{legId:guid}")]
    public async Task<IActionResult> UpdateLeg(
        Guid tripId, Guid legId, [FromBody] UpdateTripLegRequest request, CancellationToken ct)
    {
        await _mediator.Send(new UpdateTripLegCommand(
            tripId,
            legId,
            GetUserId(),
            request.Order,
            request.Name,
            request.DestinationCity,
            request.DestinationCountry,
            request.Latitude,
            request.Longitude,
            request.StartDate,
            request.EndDate,
            request.Notes), ct);

        return NoContent();
    }

    [HttpDelete("{legId:guid}")]
    public async Task<IActionResult> DeleteLeg(Guid tripId, Guid legId, CancellationToken ct)
    {
        await _mediator.Send(new DeleteTripLegCommand(tripId, legId, GetUserId()), ct);
        return NoContent();
    }
}

public sealed record AddTripLegRequest(
    string Name,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Notes);

public sealed record UpdateTripLegRequest(
    int? Order,
    string? Name,
    string? DestinationCity,
    string? DestinationCountry,
    decimal? Latitude,
    decimal? Longitude,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Notes);
