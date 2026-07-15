using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.IntegrationEvents;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Features.SettleDebt;

public sealed record SettleDebtCommand(Guid DebtRecordId, Guid SettledByUserId) : ICommand;

public sealed class SettleDebtHandler : ICommandHandler<SettleDebtCommand>
{
    private readonly ExpenseDbContext _dbContext;
    private readonly IEventBus _eventBus;

    public SettleDebtHandler(ExpenseDbContext dbContext, IEventBus eventBus)
    {
        _dbContext = dbContext;
        _eventBus = eventBus;
    }

    public async Task<MediatR.Unit> Handle(SettleDebtCommand request, CancellationToken cancellationToken)
    {
        var debt = await _dbContext.DebtRecords
            .FirstOrDefaultAsync(d => d.Id == request.DebtRecordId, cancellationToken)
            ?? throw new NotFoundException("khoản nợ", request.DebtRecordId);

        if (debt.IsSettled)
        {
            throw new ConflictException("Khoản nợ này đã được tất toán.");
        }

        // Only the debtor (FromUserId) or the creditor (ToUserId) can settle
        if (debt.FromUserId != request.SettledByUserId && debt.ToUserId != request.SettledByUserId)
        {
            throw new ForbiddenAccessException("Chỉ người nợ hoặc người cho nợ mới có thể tất toán khoản nợ này.");
        }

        debt.IsSettled = true;
        debt.SettledAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        await _eventBus.PublishAsync(new DebtSettledEvent
        {
            DebtRecordId = debt.Id,
            TripId = debt.TripId,
            FromUserId = debt.FromUserId,
            ToUserId = debt.ToUserId,
            Amount = debt.Amount,
            Currency = debt.Currency
        }, cancellationToken);

        return MediatR.Unit.Value;
    }
}
