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

    /// <summary>
    /// Decrypts a protected account number. Throws when the payload is missing
    /// or Data Protection keys cannot unprotect it (do not treat as empty account).
    /// </summary>
    public string Unprotect(string? protectedValue)
    {
        if (string.IsNullOrWhiteSpace(protectedValue))
        {
            throw new InvalidOperationException("Missing encrypted payment account value.");
        }

        try
        {
            return _protector.Unprotect(protectedValue);
        }
        catch (CryptographicException ex)
        {
            throw new InvalidOperationException(
                "Unable to decrypt payment account. Data protection keys may have rotated or been lost.",
                ex);
        }
    }
}
