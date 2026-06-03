namespace BuildingBlocks.AI.Contracts;

/// <summary>
/// Structured result returned by the AI OCR bill-scanning endpoint.
/// </summary>
public sealed class OcrBillResult
{
    public bool IsSuccess { get; set; }
    public string? ErrorMessage { get; set; }
    public List<BillItem> Items { get; set; } = new();
    public decimal TotalAmount { get; set; }
    public string Currency { get; set; } = "VND";
}

public sealed class BillItem
{
    public string ItemName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int Quantity { get; set; } = 1;

    /// <summary>
    /// Optional user ID if the AI can determine who paid for this item.
    /// </summary>
    public Guid? PaidByUserId { get; set; }
}
