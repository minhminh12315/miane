using Expense.API.Features.CreateExpense;
using Expense.API.Features.GetTripBalances;
using Expense.API.Features.GetTripExpenses;
using Expense.API.Features.SettleDebt;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace Expense.API.Controllers;

[ApiController]
[Route("expenses")]
public class ExpensesController : ControllerBase
{
    private readonly IMediator _mediator;

    public ExpensesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    private Guid GetUserId() =>
        Guid.TryParse(Request.Headers["X-User-Id"].FirstOrDefault(), out var id)
            ? id : throw new UnauthorizedAccessException("Missing X-User-Id header.");

    [HttpPost]
    public async Task<IActionResult> CreateExpense([FromBody] CreateExpenseRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(new CreateExpenseCommand(
            request.TripId,
            request.Description,
            request.Amount,
            request.Currency ?? "VND",
            request.TripBaseCurrency ?? "VND",
            GetUserId(),
            request.SplitType,
            request.Splits,
            request.Title,
            request.Category,
            request.PaidAt,
            request.PaymentSources), ct);

        return Created($"/expenses/{result.ExpenseId}", result);
    }

    [HttpGet("trip/{tripId:guid}")]
    public async Task<IActionResult> GetTripExpenses(Guid tripId, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetTripExpensesQuery(tripId), ct);
        return Ok(result);
    }

    [HttpGet("trip/{tripId:guid}/balances")]
    public async Task<IActionResult> GetTripBalances(Guid tripId, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetTripBalancesQuery(tripId), ct);
        return Ok(result);
    }

    [HttpPost("settle")]
    public async Task<IActionResult> SettleDebt([FromBody] SettleDebtRequest request, CancellationToken ct)
    {
        await _mediator.Send(new SettleDebtCommand(request.DebtRecordId, GetUserId()), ct);
        return NoContent();
    }
}

public sealed record CreateExpenseRequest(
    Guid TripId,
    string Description,
    decimal Amount,
    string? Currency,
    string? TripBaseCurrency,
    Domain.Enums.SplitType SplitType,
    List<ExpenseSplitDto> Splits,
    string? Title = null,
    string? Category = null,
    DateTime? PaidAt = null,
    List<ExpensePaymentSourceDto>? PaymentSources = null);

public sealed record SettleDebtRequest(Guid DebtRecordId);
