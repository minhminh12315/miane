namespace Identity.API.Models.Auth;

public class AuthResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public string TokenType { get; set; } = string.Empty;
    public AuthUserResponse User { get; set; } = new();
    public DateTime ExpiresIn { get; set; }
    public List<string> Permissions { get; set; } = new();
    public List<string> Roles { get; set; } = new();

}

public class AuthUserResponse
{
    public Guid Id { get; set; }
    public string? Email { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public bool IsEmployee { get; set; }
}
