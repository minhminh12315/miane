using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class PaymentWebhookEvent : BaseEntity
{
    public PaymentProvider Provider { get; set; }
    public Guid? PaymentId { get; set; }
    public string? ProviderEventId { get; set; }
    public string? SignatureHash { get; set; }
    public string PayloadJson { get; set; } = "{}";
    public DateTime ReceivedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
    public WebhookProcessingStatus ProcessingStatus { get; set; } = WebhookProcessingStatus.Received;
    public string? Error { get; set; }
}
