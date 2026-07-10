using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class Payment : AggregateRoot
{
    public Guid TripId { get; set; }
    public PaymentPurpose Purpose { get; set; }
    public Guid PayerUserId { get; set; }
    public Guid PayeeUserId { get; set; }
    public Guid? ReceivingPaymentMethodId { get; set; }
    public PaymentProvider Provider { get; set; }
    public string? ProviderOrderId { get; set; }
    public string? ProviderTransactionId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public string ReferenceCode { get; set; } = string.Empty;
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime? ExpiresAt { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public Guid? ConfirmedByUserId { get; set; }
    public string? FailureCode { get; set; }
    public string? FailureMessage { get; set; }
    public string IdempotencyKey { get; set; } = string.Empty;
}
