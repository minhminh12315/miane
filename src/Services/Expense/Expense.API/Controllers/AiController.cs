using Expense.API.Features.ScanBill;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses/ai")]
public class AiController : ControllerBase
{
    private readonly IMediator _mediator;

    public AiController(IMediator mediator)
    {
        _mediator = mediator;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpPost("scan-bill")]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10 MB
    public async Task<IActionResult> ScanBill(
        [FromForm] Guid tripId,
        [FromForm] string tripBaseCurrency,
        [FromForm] IFormFile image,
        CancellationToken ct)
    {
        using var stream = image.OpenReadStream();
        var result = await _mediator.Send(new ScanBillCommand(
            tripId,
            tripBaseCurrency,
            GetUserId(),
            stream,
            image.FileName,
            new List<Guid>()), ct);

        return Ok(result);
    }
}
