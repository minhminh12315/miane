using System;
using System.Threading.Tasks;
using Identity.API.Models;
using Identity.API.Models.Auth;

namespace Identity.API.Services
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task LogoutAsync(string userId);
        Task SendRegistrationOtpAsync(RegisterRequest request);
        Task<AuthResponse> VerifyRegistrationOtpAsync(string email, string otpCode);
        Task<AuthResponse> UpgradeToProAsync(Guid userId);
    }
}
