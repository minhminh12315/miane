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
        Task<AuthResponse?> RefreshAsync(RefreshTokenRequest request);
        Task LogoutAsync(string userId);
        Task SendRegistrationOtpAsync(RegisterRequest request);
        Task<AuthResponse> VerifyRegistrationOtpAsync(string email, string otpCode);
        Task SendPasswordResetOtpAsync(ForgotPasswordRequest request);
        Task ResetPasswordAsync(ResetPasswordRequest request);
        Task<AuthResponse> UpgradeToProAsync(Guid userId, UpgradeProRequest? purchase = null);
        Task<AuthResponse> LoginGoogleAsync(GoogleLoginRequest request);
    }
}
