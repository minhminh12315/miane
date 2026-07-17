using Microsoft.AspNetCore.DataProtection;
using System.Security.Cryptography;

namespace Expense.API.Services;

public sealed class PaymentAccountProtector
{
    private readonly IDataProtector _protector;

    public PaymentAccountProtector(IDataProtectionProvider provider)
    {
        _protector = provider.CreateProtector("Miane.Expense.PaymentAccounts.v1");
    }

    public string Protect(string value) => _protector.Protect(value);

    public string Unprotect(string? protectedValue)
    {
        if (string.IsNullOrWhiteSpace(protectedValue))
        {
            return string.Empty;
        }

        try
        {
            return _protector.Unprotect(protectedValue);
        }
        catch (CryptographicException)
        {
            return string.Empty;
        }
    }
}
