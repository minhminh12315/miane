namespace Identity.API.Services;

public interface IEmailService
{
    Task SendOtpAsync(string toEmail, string otpCode);
    Task SendPasswordResetOtpAsync(string toEmail, string otpCode);
}
