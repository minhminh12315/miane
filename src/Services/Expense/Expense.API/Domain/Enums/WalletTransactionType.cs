namespace Expense.API.Domain.Enums;

public enum WalletTransactionType
{
    ContributionCredit = 0,
    ExpenseDebit = 1,
    RefundCredit = 2,
    SettlementCredit = 3,
    SettlementDebit = 4,
    CustodianTransfer = 5,
    AdjustmentCredit = 6,
    AdjustmentDebit = 7,
    Reversal = 8
}
