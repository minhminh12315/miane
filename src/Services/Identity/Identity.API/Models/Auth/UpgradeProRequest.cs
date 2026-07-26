namespace Identity.API.Models.Auth;

/// <summary>
/// Client-supplied store purchase evidence for Pro upgrade.
/// Full App Store / Play verification should validate <see cref="ReceiptData"/>
/// before flipping tier; non-Development already requires a non-empty receipt.
/// </summary>
public class UpgradeProRequest
{
    /// <summary>"ios", "android", or "dev" (Development only).</summary>
    public string? Platform { get; set; }

    /// <summary>Store receipt / purchase token (serverVerificationData).</summary>
    public string? ReceiptData { get; set; }

    public string? ProductId { get; set; }

    public string? TransactionId { get; set; }
}
