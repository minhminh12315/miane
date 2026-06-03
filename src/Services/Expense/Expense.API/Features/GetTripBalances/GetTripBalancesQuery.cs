using BuildingBlocks.CQRS;
using Expense.API.Data;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Features.GetTripBalances;

public sealed record GetTripBalancesQuery(Guid TripId) : IQuery<TripBalancesResponse>;

public sealed record TripBalancesResponse(
    Guid TripId,
    List<DebtResponse> UnsettledDebts,
    List<DebtResponse> SettledDebts);

public sealed record DebtResponse(
    Guid DebtRecordId,
    Guid FromUserId,
    Guid ToUserId,
    decimal Amount,
    string Currency,
    bool IsSettled,
    DateTime? SettledAt);

public sealed class GetTripBalancesHandler : IQueryHandler<GetTripBalancesQuery, TripBalancesResponse>
{
    private readonly ExpenseDbContext _dbContext;

    public GetTripBalancesHandler(ExpenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<TripBalancesResponse> Handle(GetTripBalancesQuery request, CancellationToken cancellationToken)
    {
        var debts = await _dbContext.DebtRecords
            .Where(d => d.TripId == request.TripId)
            .OrderByDescending(d => d.Amount)
            .ToListAsync(cancellationToken);

        var unsettled = debts.Where(d => !d.IsSettled).Select(MapToResponse).ToList();
        var settled = debts.Where(d => d.IsSettled).Select(MapToResponse).ToList();

        return new TripBalancesResponse(request.TripId, unsettled, settled);
    }

    private static DebtResponse MapToResponse(Domain.Entities.DebtRecord d) => new(
        d.Id, d.FromUserId, d.ToUserId, d.Amount, d.Currency, d.IsSettled, d.SettledAt);
}
