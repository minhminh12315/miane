using Expense.API.Features.ContributeToPool;
using Expense.API.Features.GetTripPool;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses/pool")]
public class TripPoolController : ControllerBase
{
    private readonly IMediator _mediator;

    public TripPoolController(IMediator mediator)
    {
        _mediator = mediator;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpPost("contribute")]
    public async Task<IActionResult> Contribute([FromBody] ContributeRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(new ContributeToPoolCommand(
            request.TripId, GetUserId(), request.Amount, request.Currency ?? "VND"), ct);

        return Ok(result);
    }

    [HttpGet("{tripId:guid}")]
    public async Task<IActionResult> GetPool(Guid tripId, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetTripPoolQuery(tripId), ct);
        return result is not null ? Ok(result) : NotFound(new { message = "Chuyến đi này chưa có quỹ nhóm." });
    }
}

public sealed record ContributeRequest(Guid TripId, decimal Amount, string? Currency);
