using BuildingBlocks.CQRS;
using Expense.API.Data;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Features.GetTripPool;

public sealed record GetTripPoolQuery(Guid TripId) : IQuery<TripPoolResponse?>;

public sealed record TripPoolResponse(
    Guid PoolId,
    decimal Balance,
    string Currency,
    List<PoolContributionResponse> Contributions);

public sealed record PoolContributionResponse(
    Guid UserId,
    decimal Amount,
    DateTime ContributedAt);

public sealed class GetTripPoolHandler : IQueryHandler<GetTripPoolQuery, TripPoolResponse?>
{
    private readonly ExpenseDbContext _dbContext;

    public GetTripPoolHandler(ExpenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<TripPoolResponse?> Handle(GetTripPoolQuery request, CancellationToken cancellationToken)
    {
        var pool = await _dbContext.TripPools
            .Include(p => p.Contributions)
            .FirstOrDefaultAsync(p => p.TripId == request.TripId, cancellationToken);

        if (pool is null) return null;

        return new TripPoolResponse(
            pool.Id,
            pool.Balance,
            pool.Currency,
            pool.Contributions
                .OrderByDescending(c => c.ContributedAt)
                .Select(c => new PoolContributionResponse(c.UserId, c.Amount, c.ContributedAt))
                .ToList());
    }
}
