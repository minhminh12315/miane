namespace Expense.API.Services;

/// <summary>
/// Interface for exchange rate providers. Swap the static implementation
/// for a real API provider (e.g., ExchangeRate-API, Fixer.io) in production.
/// </summary>
public interface IExchangeRateProvider
{
    Task<decimal> GetRateAsync(string fromCurrency, string toCurrency, DateTime? date = null);
}
