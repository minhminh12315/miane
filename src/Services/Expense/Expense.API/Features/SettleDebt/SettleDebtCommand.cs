using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.Domain.Enums;
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
        var legacy = await _dbContext.DebtRecords
            .FirstOrDefaultAsync(d => d.Id == request.DebtRecordId, cancellationToken);

        if (legacy is not null)
        {
            if (legacy.IsSettled)
            {
                throw new ConflictException("Khoản nợ này đã được tất toán.");
            }

            // Only the creditor can finalize settlement after payment.
            if (legacy.ToUserId != request.SettledByUserId)
            {
                throw new ForbiddenAccessException(
                    "Chỉ người nhận tiền (chủ nợ) mới có thể xác nhận đã nhận thanh toán.");
            }

            legacy.IsSettled = true;
            legacy.SettledAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);

            await _eventBus.PublishAsync(new DebtSettledEvent
            {
                DebtRecordId = legacy.Id,
                TripId = legacy.TripId,
                FromUserId = legacy.FromUserId,
                ToUserId = legacy.ToUserId,
                Amount = legacy.Amount,
                Currency = legacy.Currency
            }, cancellationToken);

            return MediatR.Unit.Value;
        }

        var v2 = await _dbContext.Debts
            .FirstOrDefaultAsync(d => d.Id == request.DebtRecordId, cancellationToken)
            ?? throw new NotFoundException("khoản nợ", request.DebtRecordId);

        if (v2.Status == DebtStatus.Settled)
        {
            throw new ConflictException("Khoản nợ này đã được tất toán.");
        }

        if (v2.Status == DebtStatus.Superseded)
        {
            throw new ConflictException("Khoản nợ này đã bị thay thế bởi lần tính toán mới.");
        }

        if (v2.ToUserId != request.SettledByUserId)
        {
            throw new ForbiddenAccessException(
                "Chỉ người nhận tiền (chủ nợ) mới có thể xác nhận đã nhận thanh toán.");
        }

        v2.Status = DebtStatus.Settled;
        v2.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync(cancellationToken);

        await _eventBus.PublishAsync(new DebtSettledEvent
        {
            DebtRecordId = v2.Id,
            TripId = v2.TripId,
            FromUserId = v2.FromUserId,
            ToUserId = v2.ToUserId,
            Amount = v2.Amount,
            Currency = v2.Currency
        }, cancellationToken);

        return MediatR.Unit.Value;
    }
}
