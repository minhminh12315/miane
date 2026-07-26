using System.ComponentModel.DataAnnotations;

namespace Identity.API.Models.Auth;

public sealed class RefreshTokenRequest
{
    /// <summary>
    /// Optional when the refresh token is indexed in cache.
    /// Preferred: omit and let the server resolve the user from the refresh token.
    /// </summary>
    public Guid? UserId { get; set; }

    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
