namespace Expense.API.Services;

public sealed class VietQrOptions
{
    public string BaseUrl { get; set; } = "https://api.vietqr.io/";
    public string? ClientId { get; set; }
    public string? ApiKey { get; set; }
    public int BanksCacheHours { get; set; } = 24;
    public string DefaultFormat { get; set; } = "text";
    public string DefaultTemplate { get; set; } = "compact";
}
