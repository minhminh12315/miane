using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class PaymentMethod : AggregateRoot
{
    public Guid UserId { get; set; }
    public PaymentMethodType Type { get; set; }
    public PaymentProvider Provider { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? BankCode { get; set; }
    public string? BankAccountNoEncrypted { get; set; }
    public string? BankAccountName { get; set; }
    public string? WalletPhoneEncrypted { get; set; }
    public bool IsDefaultReceive { get; set; }
    public string? CapabilitiesJson { get; set; }
    public PaymentMethodStatus Status { get; set; } = PaymentMethodStatus.Active;
}
