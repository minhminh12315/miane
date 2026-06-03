namespace Expense.API.Services;

/// <summary>
/// Converts amounts between currencies using the configured exchange rate provider.
/// </summary>
public sealed class CurrencyConversionService
{
    private readonly IExchangeRateProvider _rateProvider;

    public CurrencyConversionService(IExchangeRateProvider rateProvider)
    {
        _rateProvider = rateProvider;
    }

    /// <summary>
    /// Converts an amount from one currency to another.
    /// Returns (convertedAmount, exchangeRate).
    /// </summary>
    public async Task<(decimal ConvertedAmount, decimal ExchangeRate)> ConvertAsync(
        decimal amount,
        string fromCurrency,
        string toCurrency,
        DateTime? date = null)
    {
        if (string.Equals(fromCurrency, toCurrency, StringComparison.OrdinalIgnoreCase))
        {
            return (amount, 1m);
        }

        var rate = await _rateProvider.GetRateAsync(fromCurrency, toCurrency, date);
        var convertedAmount = Math.Round(amount * rate, 4);
        return (convertedAmount, rate);
    }
}
