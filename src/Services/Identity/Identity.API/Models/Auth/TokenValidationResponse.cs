namespace Identity.API.Models.Auth;

public class TokenValidationResponse
{
    public bool IsValid { get; set; }
    public Guid UserId { get; set; }
    public string? Email { get; set; }
    public string FullName { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = new();
    public List<string> Permissions { get; set; } = new();
}
