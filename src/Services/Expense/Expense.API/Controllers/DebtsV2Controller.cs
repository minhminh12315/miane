using Expense.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses/trip/{tripId:guid}/debts-v2")]
public class DebtsV2Controller : ControllerBase
{
    private readonly DebtOptimizationServiceV2 _debtOptimization;

    public DebtsV2Controller(DebtOptimizationServiceV2 debtOptimization)
    {
        _debtOptimization = debtOptimization;
    }

    [HttpPost("recalculate")]
    public async Task<IActionResult> Recalculate(Guid tripId, [FromBody] RecalculateDebtsRequest? request, CancellationToken ct)
    {
        var debts = await _debtOptimization.RecalculateAsync(tripId, request?.Currency ?? "VND", ct);

        return Ok(new RecalculateDebtsResponse(
            tripId,
            debts.Select(d => new DebtV2Response(d.Id, d.FromUserId, d.ToUserId, d.Amount, d.Currency, d.Status.ToString(), d.CalculationRunId)).ToList()));
    }
}

public sealed record RecalculateDebtsRequest(string? Currency);

public sealed record RecalculateDebtsResponse(Guid TripId, IReadOnlyList<DebtV2Response> Debts);

public sealed record DebtV2Response(
    Guid DebtId,
    Guid FromUserId,
    Guid ToUserId,
    decimal Amount,
    string Currency,
    string Status,
    Guid CalculationRunId);
