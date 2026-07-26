using Microsoft.Extensions.Hosting;

namespace BuildingBlocks.Security;

/// <summary>
/// Rejects known development JWT signing keys outside Development so a
/// compose/appsettings default cannot ship to production unchanged.
/// </summary>
public static class JwtSigningKeyGuard
{
    public const string DevelopmentDefaultKey =
        "Miane_Development_Jwt_Signing_Key_Change_In_Production_2026!@#";

    public static string RequireConfiguredKey(string? jwtKey, IHostEnvironment environment)
    {
        if (string.IsNullOrWhiteSpace(jwtKey))
        {
            throw new InvalidOperationException(
                "Jwt:Key is not configured. Set Jwt__Key / JWT_SIGNING_KEY before starting.");
        }

        if (!environment.IsDevelopment()
            && string.Equals(jwtKey, DevelopmentDefaultKey, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "Refusing to start with the development JWT signing key outside Development. "
                + "Set a strong unique Jwt:Key (JWT_SIGNING_KEY).");
        }

        return jwtKey;
    }
}
