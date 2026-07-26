using BuildingBlocks.CQRS;
using Expense.API.Data;
using Expense.API.Domain.Enums;
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
        // Prefer V2 Debts when the trip has any non-superseded V2 rows (wallet/payment-source path).
        var hasV2 = await _dbContext.Debts.AnyAsync(
            d => d.TripId == request.TripId && d.Status != DebtStatus.Superseded,
            cancellationToken);

        if (hasV2)
        {
            var v2Debts = await _dbContext.Debts
                .Where(d => d.TripId == request.TripId && d.Status != DebtStatus.Superseded)
                .OrderByDescending(d => d.Amount)
                .ToListAsync(cancellationToken);

            var unsettledV2 = v2Debts
                .Where(d => d.Status == DebtStatus.Open)
                .Select(MapV2)
                .ToList();
            var settledV2 = v2Debts
                .Where(d => d.Status == DebtStatus.Settled)
                .Select(MapV2)
                .ToList();

            return new TripBalancesResponse(request.TripId, unsettledV2, settledV2);
        }

        var debts = await _dbContext.DebtRecords
            .Where(d => d.TripId == request.TripId)
            .OrderByDescending(d => d.Amount)
            .ToListAsync(cancellationToken);

        var unsettled = debts.Where(d => !d.IsSettled).Select(MapLegacy).ToList();
        var settled = debts.Where(d => d.IsSettled).Select(MapLegacy).ToList();

        return new TripBalancesResponse(request.TripId, unsettled, settled);
    }

    private static DebtResponse MapLegacy(Domain.Entities.DebtRecord d) => new(
        d.Id, d.FromUserId, d.ToUserId, d.Amount, d.Currency, d.IsSettled, d.SettledAt);

    private static DebtResponse MapV2(Domain.Entities.Debt d) => new(
        d.Id,
        d.FromUserId,
        d.ToUserId,
        d.Amount,
        d.Currency,
        d.Status == DebtStatus.Settled,
        d.Status == DebtStatus.Settled ? d.UpdatedAt ?? d.CreatedAt : null);
}
