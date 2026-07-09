using System.Threading.Tasks;
using Identity.API.Models;
using Identity.API.Models.Auth;

namespace Identity.API.Services
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task<AuthResponse> LoginWithGoogleAsync(GoogleLoginRequest request);
        Task LogoutAsync(string userId);
    }
}
