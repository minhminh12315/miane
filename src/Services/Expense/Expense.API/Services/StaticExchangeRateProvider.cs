namespace Expense.API.Services;

/// <summary>
/// Static fallback exchange rate provider with hardcoded rates relative to USD.
/// For development/offline use. Replace with a real API provider in production.
/// </summary>
public sealed class StaticExchangeRateProvider : IExchangeRateProvider
{
    // Rates: 1 USD = X units of target currency (approximate)
    private static readonly Dictionary<string, decimal> RatesToUsd = new(StringComparer.OrdinalIgnoreCase)
    {
        { "USD", 1m },
        { "VND", 25_400m },
        { "EUR", 0.92m },
        { "GBP", 0.79m },
        { "JPY", 157.5m },
        { "KRW", 1_380m },
        { "THB", 36.5m },
        { "SGD", 1.35m },
        { "AUD", 1.53m },
        { "CNY", 7.24m },
        { "TWD", 32.5m },
        { "MYR", 4.72m },
        { "PHP", 56.5m },
        { "IDR", 16_200m },
        { "INR", 83.5m },
    };

    public Task<decimal> GetRateAsync(string fromCurrency, string toCurrency, DateTime? date = null)
    {
        if (string.Equals(fromCurrency, toCurrency, StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(1m);
        }

        if (!RatesToUsd.TryGetValue(fromCurrency, out var fromRate))
        {
            throw new BuildingBlocks.Exceptions.DomainException(
                $"Unsupported currency: {fromCurrency}", "UNSUPPORTED_CURRENCY");
        }

        if (!RatesToUsd.TryGetValue(toCurrency, out var toRate))
        {
            throw new BuildingBlocks.Exceptions.DomainException(
                $"Unsupported currency: {toCurrency}", "UNSUPPORTED_CURRENCY");
        }

        // Convert: fromCurrency → USD → toCurrency
        var rate = toRate / fromRate;
        return Task.FromResult(Math.Round(rate, 8));
    }
}
