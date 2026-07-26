using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.Domain.Entities;
using Expense.API.Domain.Enums;
using Expense.API.IntegrationEvents;
using Expense.API.Services;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Features.CreateExpense;

public sealed class CreateExpenseHandler : ICommandHandler<CreateExpenseCommand, CreateExpenseResult>
{
    private readonly ExpenseDbContext _dbContext;
    private readonly CurrencyConversionService _currencyService;
    private readonly DebtSimplificationService _debtService;
    private readonly DebtOptimizationServiceV2 _debtServiceV2;
    private readonly WalletLedgerService _walletLedger;
    private readonly SplitCalculationService _splitCalculation;
    private readonly IEventBus _eventBus;

    public CreateExpenseHandler(
        ExpenseDbContext dbContext,
        CurrencyConversionService currencyService,
        DebtSimplificationService debtService,
        DebtOptimizationServiceV2 debtServiceV2,
        WalletLedgerService walletLedger,
        SplitCalculationService splitCalculation,
        IEventBus eventBus)
    {
        _dbContext = dbContext;
        _currencyService = currencyService;
        _debtService = debtService;
        _debtServiceV2 = debtServiceV2;
        _walletLedger = walletLedger;
        _splitCalculation = splitCalculation;
        _eventBus = eventBus;
    }

    public async Task<CreateExpenseResult> Handle(CreateExpenseCommand request, CancellationToken cancellationToken)
    {
        var strategy = _dbContext.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var dbTransaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);

            var (convertedAmount, exchangeRate) = await _currencyService.ConvertAsync(
                request.Amount, request.Currency, request.TripBaseCurrency);

            var expense = new ExpenseEntity
            {
                TripId = request.TripId,
                Title = request.Title,
                Description = request.Description,
                Category = request.Category,
                Amount = request.Amount,
                Currency = request.Currency.ToUpperInvariant(),
                ConvertedAmount = convertedAmount,
                ExchangeRate = exchangeRate,
                PaidByUserId = request.PaidByUserId,
                SplitType = request.SplitType,
                IsPaidFromPool = request.SplitType == SplitType.TripPool,
                PaidAt = request.PaidAt ?? DateTime.UtcNow
            };

            var hasPaymentSources = request.PaymentSources is { Count: > 0 };

            if (hasPaymentSources)
            {
                ValidatePaymentSources(request.PaymentSources!, convertedAmount);

                if (request.SplitType != SplitType.TripPool)
                {
                    ApplySplits(expense, request, convertedAmount);
                }

                foreach (var paymentSource in request.PaymentSources!)
                {
                    expense.AddPaymentSource(new ExpensePaymentSource
                    {
                        SourceType = paymentSource.SourceType,
                        TripWalletId = paymentSource.TripWalletId,
                        UserId = paymentSource.UserId,
                        PaymentId = paymentSource.PaymentId,
                        Amount = paymentSource.Amount,
                        Currency = request.TripBaseCurrency.ToUpperInvariant()
                    });
                }
            }
            else if (request.SplitType == SplitType.TripPool)
            {
                var pool = await _dbContext.TripPools
                    .FirstOrDefaultAsync(p => p.TripId == request.TripId, cancellationToken)
                    ?? throw new NotFoundException("quỹ nhóm", request.TripId);

                pool.Deduct(convertedAmount);
            }
            else
            {
                ApplySplits(expense, request, convertedAmount);
            }

            await _dbContext.Expenses.AddAsync(expense, cancellationToken);

            if (hasPaymentSources)
            {
                foreach (var source in expense.PaymentSources.Where(s => s.SourceType == Domain.Enums.ExpensePaymentSourceType.Wallet))
                {
                    if (!source.TripWalletId.HasValue)
                    {
                        throw new DomainException("Nguồn thanh toán từ ví phải kèm mã ví.", "WALLET_SOURCE_REQUIRES_WALLET_ID");
                    }

                    var walletTransaction = await _walletLedger.PostAsync(
                        new WalletPostRequest(
                            source.TripWalletId.Value,
                            Domain.Enums.WalletTransactionType.ExpenseDebit,
                            Domain.Enums.TransactionDirection.Debit,
                            source.Amount,
                            source.Currency,
                            request.PaidByUserId,
                            ExpenseId: expense.Id,
                            PaymentId: source.PaymentId,
                            OccurredAt: expense.PaidAt),
                        cancellationToken,
                        manageTransaction: false);

                    source.WalletTransactionId = walletTransaction.Id;
                }
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            await dbTransaction.CommitAsync(cancellationToken);

            if (hasPaymentSources)
            {
                await _debtServiceV2.RecalculateAsync(request.TripId, request.TripBaseCurrency, cancellationToken);
            }
            else if (!expense.IsPaidFromPool)
            {
                await _debtService.SimplifyDebtsAsync(request.TripId, request.TripBaseCurrency, cancellationToken);
            }

            await _eventBus.PublishAsync(new ExpenseCreatedEvent
            {
                ExpenseId = expense.Id,
                TripId = request.TripId,
                Description = request.Description,
                Amount = request.Amount,
                Currency = request.Currency,
                PaidByUserId = request.PaidByUserId
            }, cancellationToken);

            return new CreateExpenseResult(expense.Id, convertedAmount, request.TripBaseCurrency);
        });
    }

    private void ApplySplits(ExpenseEntity expense, CreateExpenseCommand request, decimal convertedAmount)
    {
        var calculated = _splitCalculation.Calculate(
            convertedAmount,
            request.SplitType,
            request.Splits.Select(s => new SplitParticipantInput(
                s.UserId,
                s.Amount,
                s.Percentage)).ToList());

        foreach (var share in calculated.Shares)
        {
            expense.AddSplit(new ExpenseSplit
            {
                UserId = share.UserId,
                Amount = share.Amount
            });
            expense.AddParticipant(new ExpenseParticipant
            {
                UserId = share.UserId,
                ShareAmount = share.Amount
            });
        }
    }

    private static void ValidatePaymentSources(List<ExpensePaymentSourceDto> sources, decimal convertedAmount)
    {
        if (sources.Any(s => s.Amount <= 0))
        {
            throw new DomainException("Số tiền của nguồn thanh toán phải lớn hơn 0.", "INVALID_PAYMENT_SOURCE_AMOUNT");
        }

        var sourceTotal = sources.Sum(s => s.Amount);
        if (Math.Abs(sourceTotal - convertedAmount) > 0.01m)
        {
            throw new DomainException("Tổng các nguồn thanh toán phải bằng số tiền chi tiêu đã quy đổi.", "PAYMENT_SOURCE_TOTAL_MISMATCH");
        }
    }
}
