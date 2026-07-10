using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class QRPayment : BaseEntity
{
    public Guid PaymentId { get; set; }
    public PaymentProvider Provider { get; set; }
    public QrPaymentType QrType { get; set; } = QrPaymentType.EmvCo;
    public string? QrPayload { get; set; }
    public string? QrImageUrl { get; set; }
    public string? DeepLink { get; set; }
    public string? UniversalLink { get; set; }
    public string? PayUrl { get; set; }
    public string? ProviderPayloadJson { get; set; }
    public QrPaymentStatus Status { get; set; } = QrPaymentStatus.Active;

    public Payment Payment { get; set; } = null!;
}
