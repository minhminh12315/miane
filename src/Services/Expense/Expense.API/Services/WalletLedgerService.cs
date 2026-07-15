using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Expense.API.Domain.Entities;
using Expense.API.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Services;

public sealed record WalletPostRequest(
    Guid WalletId,
    WalletTransactionType Type,
    TransactionDirection Direction,
    decimal Amount,
    string Currency,
    Guid ActorUserId,
    Guid? CounterpartyUserId = null,
    Guid? ExpenseId = null,
    Guid? FundContributionId = null,
    Guid? PaymentId = null,
    Guid? ReversesTransactionId = null,
    DateTime? OccurredAt = null,
    string? MetadataJson = null);

public sealed class WalletLedgerService
{
    private readonly ExpenseDbContext _dbContext;

    public WalletLedgerService(ExpenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<TripWallet> GetOrCreateWalletAsync(
        Guid tripId,
        string currency,
        Guid actorUserId,
        Guid? custodianUserId = null,
        CancellationToken cancellationToken = default)
    {
        var wallet = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.TripId == tripId, cancellationToken);

        if (wallet is not null)
        {
            return wallet;
        }

        wallet = new TripWallet
        {
            TripId = tripId,
            Name = "Trip wallet",
            Currency = currency.ToUpperInvariant(),
            CurrentCustodianUserId = custodianUserId ?? actorUserId
        };

        await _dbContext.TripWallets.AddAsync(wallet, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return wallet;
    }

    public async Task<WalletTransaction> PostAsync(
        WalletPostRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Amount < 0)
        {
            throw new DomainException("Số tiền giao dịch ví không được là số âm.", "INVALID_WALLET_TRANSACTION_AMOUNT");
        }

        await using var dbTransaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);

        var wallet = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.Id == request.WalletId, cancellationToken)
            ?? throw new NotFoundException("ví chung", request.WalletId);

        if (!string.Equals(wallet.Currency, request.Currency, StringComparison.OrdinalIgnoreCase))
        {
            throw new DomainException("Đơn vị tiền tệ của giao dịch phải khớp với đơn vị tiền tệ của ví.", "WALLET_CURRENCY_MISMATCH");
        }

        var walletTransaction = new WalletTransaction
        {
            TripWalletId = wallet.Id,
            TransactionNo = await GenerateTransactionNoAsync(wallet.TripId, cancellationToken),
            Type = request.Type,
            Direction = request.Direction,
            Amount = request.Amount,
            Currency = request.Currency.ToUpperInvariant(),
            ActorUserId = request.ActorUserId,
            CounterpartyUserId = request.CounterpartyUserId,
            ExpenseId = request.ExpenseId,
            FundContributionId = request.FundContributionId,
            PaymentId = request.PaymentId,
            ReversesTransactionId = request.ReversesTransactionId,
            OccurredAt = request.OccurredAt ?? DateTime.UtcNow,
            MetadataJson = request.MetadataJson
        };

        wallet.ApplyPostedTransaction(walletTransaction);
        await _dbContext.WalletTransactions.AddAsync(walletTransaction, cancellationToken);

        _dbContext.TransactionHistories.Add(new TransactionHistory
        {
            TripId = wallet.TripId,
            ActorUserId = request.ActorUserId,
            EntityType = "wallet_transaction",
            EntityId = walletTransaction.Id,
            Action = "posted",
            Amount = request.Amount,
            Currency = request.Currency.ToUpperInvariant(),
            Title = BuildHistoryTitle(request.Type, request.Amount, request.Currency),
            OccurredAt = walletTransaction.OccurredAt,
            MetadataJson = request.MetadataJson
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
        await dbTransaction.CommitAsync(cancellationToken);
        return walletTransaction;
    }

    public async Task<decimal> RebuildBalanceAsync(Guid walletId, CancellationToken cancellationToken = default)
    {
        var wallet = await _dbContext.TripWallets
            .FirstOrDefaultAsync(w => w.Id == walletId, cancellationToken)
            ?? throw new NotFoundException("ví chung", walletId);

        var transactions = await _dbContext.WalletTransactions
            .Where(t => t.TripWalletId == walletId && t.Status == WalletTransactionStatus.Posted)
            .OrderBy(t => t.OccurredAt)
            .ThenBy(t => t.CreatedAt)
            .ToListAsync(cancellationToken);

        var balance = wallet.OpeningBalance;
        var totalContributed = 0m;
        var totalSpent = 0m;

        foreach (var transaction in transactions)
        {
            balance += transaction.Direction == TransactionDirection.Credit
                ? transaction.Amount
                : -transaction.Amount;

            transaction.BalanceAfter = balance;

            if (transaction.Type == WalletTransactionType.ContributionCredit)
            {
                totalContributed += transaction.Amount;
            }

            if (transaction.Type == WalletTransactionType.ExpenseDebit)
            {
                totalSpent += transaction.Amount;
            }
        }

        wallet.CurrentBalance = balance;
        wallet.TotalContributed = totalContributed;
        wallet.TotalSpent = totalSpent;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return balance;
    }

    private async Task<string> GenerateTransactionNoAsync(Guid tripId, CancellationToken cancellationToken)
    {
        var prefix = $"WT{DateTime.UtcNow:yyyyMMdd}";
        var countToday = await _dbContext.WalletTransactions
            .CountAsync(t => t.TransactionNo.StartsWith(prefix), cancellationToken);

        return $"{prefix}{countToday + 1:000000}";
    }

    private static string BuildHistoryTitle(WalletTransactionType type, decimal amount, string currency)
    {
        return type switch
        {
            WalletTransactionType.ContributionCredit => $"Fund contribution +{amount:N0} {currency}",
            WalletTransactionType.ExpenseDebit => $"Wallet expense -{amount:N0} {currency}",
            WalletTransactionType.CustodianTransfer => "Wallet custodian transferred",
            WalletTransactionType.Reversal => $"Wallet reversal {amount:N0} {currency}",
            _ => $"Wallet transaction {amount:N0} {currency}"
        };
    }
}
