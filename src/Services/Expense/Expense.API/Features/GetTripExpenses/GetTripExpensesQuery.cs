using BuildingBlocks.CQRS;
using Expense.API.Data;
using Expense.API.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Features.GetTripExpenses;

public sealed record GetTripExpensesQuery(Guid TripId) : IQuery<List<ExpenseResponse>>;

public sealed record ExpenseResponse(
    Guid Id,
    string Description,
    decimal Amount,
    string Currency,
    decimal ConvertedAmount,
    decimal ExchangeRate,
    Guid PaidByUserId,
    SplitType SplitType,
    bool IsPaidFromPool,
    DateTime CreatedAt,
    List<SplitResponse> Splits);

public sealed record SplitResponse(Guid UserId, decimal Amount, bool IsPaid);

public sealed class GetTripExpensesHandler : IQueryHandler<GetTripExpensesQuery, List<ExpenseResponse>>
{
    private readonly ExpenseDbContext _dbContext;

    public GetTripExpensesHandler(ExpenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<ExpenseResponse>> Handle(GetTripExpensesQuery request, CancellationToken cancellationToken)
    {
        var expenses = await _dbContext.Expenses
            .Include(e => e.Splits)
            .Where(e => e.TripId == request.TripId)
            .OrderByDescending(e => e.CreatedAt)
            .ToListAsync(cancellationToken);

        return expenses.Select(e => new ExpenseResponse(
            e.Id,
            e.Description,
            e.Amount,
            e.Currency,
            e.ConvertedAmount,
            e.ExchangeRate,
            e.PaidByUserId,
            e.SplitType,
            e.IsPaidFromPool,
            e.CreatedAt,
            e.Splits.Select(s => new SplitResponse(s.UserId, s.Amount, s.IsPaid)).ToList()
        )).ToList();
    }
}
