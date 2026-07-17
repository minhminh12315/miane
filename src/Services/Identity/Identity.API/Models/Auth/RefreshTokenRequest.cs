using System.ComponentModel.DataAnnotations;

namespace Identity.API.Models.Auth;

public sealed class RefreshTokenRequest
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
