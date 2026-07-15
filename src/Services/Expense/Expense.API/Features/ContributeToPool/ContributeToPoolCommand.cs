using BuildingBlocks.CQRS;
using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Features.ContributeToPool;

public sealed record ContributeToPoolCommand(
    Guid TripId,
    Guid UserId,
    decimal Amount,
    string Currency) : ICommand<ContributeToPoolResult>;

public sealed record ContributeToPoolResult(Guid TripPoolId, decimal NewBalance);

public sealed class ContributeToPoolHandler : ICommandHandler<ContributeToPoolCommand, ContributeToPoolResult>
{
    private readonly ExpenseDbContext _dbContext;

    public ContributeToPoolHandler(ExpenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ContributeToPoolResult> Handle(ContributeToPoolCommand request, CancellationToken cancellationToken)
    {
        if (request.Amount <= 0)
        {
            throw new DomainException("Số tiền đóng góp phải lớn hơn 0.", "INVALID_AMOUNT");
        }

        var pool = await _dbContext.TripPools
            .Include(p => p.Contributions)
            .FirstOrDefaultAsync(p => p.TripId == request.TripId, cancellationToken);

        if (pool is null)
        {
            // Create pool if it doesn't exist
            pool = new TripPool
            {
                TripId = request.TripId,
                Currency = request.Currency.ToUpperInvariant(),
                Balance = 0
            };
            await _dbContext.TripPools.AddAsync(pool, cancellationToken);
        }

        var contribution = new PoolContribution
        {
            TripPoolId = pool.Id,
            UserId = request.UserId,
            Amount = request.Amount,
            ContributedAt = DateTime.UtcNow
        };

        pool.AddContribution(contribution);
        await _dbContext.PoolContributions.AddAsync(contribution, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new ContributeToPoolResult(pool.Id, pool.Balance);
    }
}
