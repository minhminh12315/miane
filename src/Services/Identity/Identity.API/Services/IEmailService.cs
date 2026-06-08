namespace Identity.API.Services;

public interface IEmailService
{
    Task SendOtpAsync(string toEmail, string otpCode);
}
