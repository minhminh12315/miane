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
    private readonly IEventBus _eventBus;

    public CreateExpenseHandler(
        ExpenseDbContext dbContext,
        CurrencyConversionService currencyService,
        DebtSimplificationService debtService,
        IEventBus eventBus)
    {
        _dbContext = dbContext;
        _currencyService = currencyService;
        _debtService = debtService;
        _eventBus = eventBus;
    }

    public async Task<CreateExpenseResult> Handle(CreateExpenseCommand request, CancellationToken cancellationToken)
    {
        // Convert to base currency if needed
        var (convertedAmount, exchangeRate) = await _currencyService.ConvertAsync(
            request.Amount, request.Currency, request.TripBaseCurrency);

        var expense = new ExpenseEntity
        {
            TripId = request.TripId,
            Description = request.Description,
            Amount = request.Amount,
            Currency = request.Currency.ToUpperInvariant(),
            ConvertedAmount = convertedAmount,
            ExchangeRate = exchangeRate,
            PaidByUserId = request.PaidByUserId,
            SplitType = request.SplitType,
            IsPaidFromPool = request.SplitType == SplitType.TripPool
        };

        // Handle Trip Pool payment
        if (request.SplitType == SplitType.TripPool)
        {
            var pool = await _dbContext.TripPools
                .FirstOrDefaultAsync(p => p.TripId == request.TripId, cancellationToken)
                ?? throw new NotFoundException("TripPool", request.TripId);

            pool.Deduct(convertedAmount);
        }
        else
        {
            // Calculate splits
            var splits = CalculateSplits(request, convertedAmount);
            foreach (var split in splits)
            {
                expense.AddSplit(split);
            }
        }

        await _dbContext.Expenses.AddAsync(expense, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // Run debt simplification after every expense
        if (!expense.IsPaidFromPool)
        {
            await _debtService.SimplifyDebtsAsync(request.TripId, request.TripBaseCurrency, cancellationToken);
        }

        // Publish event
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
    }

    private static List<ExpenseSplit> CalculateSplits(CreateExpenseCommand request, decimal convertedAmount)
    {
        return request.SplitType switch
        {
            SplitType.Equal => request.Splits.Select(s => new ExpenseSplit
            {
                UserId = s.UserId,
                Amount = Math.Round(convertedAmount / request.Splits.Count, 4)
            }).ToList(),

            SplitType.Custom => request.Splits.Select(s => new ExpenseSplit
            {
                UserId = s.UserId,
                Amount = s.Amount ?? 0m
            }).ToList(),

            SplitType.Percentage => request.Splits.Select(s => new ExpenseSplit
            {
                UserId = s.UserId,
                Amount = Math.Round(convertedAmount * (s.Percentage ?? 0m) / 100m, 4)
            }).ToList(),

            _ => throw new DomainException("Invalid split type.", "INVALID_SPLIT_TYPE")
        };
    }
}
