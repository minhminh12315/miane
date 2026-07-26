using BuildingBlocks.Domain;
using BuildingBlocks.Exceptions;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class TripWallet : AggregateRoot
{
    public Guid TripId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Currency { get; set; } = "VND";
    public Guid? CurrentCustodianUserId { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal CurrentBalance { get; set; }
    public decimal TotalContributed { get; set; }
    public decimal TotalSpent { get; set; }
    public WalletStatus Status { get; set; } = WalletStatus.Active;

    private readonly List<WalletMember> _members = new();
    private readonly List<WalletTransaction> _transactions = new();

    public IReadOnlyCollection<WalletMember> Members => _members.AsReadOnly();
    public IReadOnlyCollection<WalletTransaction> Transactions => _transactions.AsReadOnly();

    public void ApplyPostedTransaction(WalletTransaction transaction)
    {
        if (transaction.Amount < 0)
        {
            throw new DomainException("Số tiền giao dịch ví không được là số âm.", "INVALID_WALLET_TRANSACTION_AMOUNT");
        }

        if (transaction.Direction == TransactionDirection.Debit && transaction.Amount > CurrentBalance)
        {
            throw new DomainException(
                $"Số dư ví không đủ. Hiện có: {CurrentBalance:F2} {Currency}, cần: {transaction.Amount:F2} {Currency}",
                "INSUFFICIENT_WALLET_BALANCE");
        }

        CurrentBalance += transaction.Direction == TransactionDirection.Credit
            ? transaction.Amount
            : -transaction.Amount;

        if (transaction.Type == WalletTransactionType.ContributionCredit)
        {
            TotalContributed += transaction.Amount;
        }

        if (transaction.Type == WalletTransactionType.ExpenseDebit)
        {
            TotalSpent += transaction.Amount;
        }

        transaction.BalanceAfter = CurrentBalance;
        transaction.Status = WalletTransactionStatus.Posted;
        Version++;
        _transactions.Add(transaction);
    }
}
