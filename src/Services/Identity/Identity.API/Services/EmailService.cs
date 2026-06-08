using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace Identity.API.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendOtpAsync(string toEmail, string otpCode)
    {
        var smtpHost = _config["Smtp:Host"] ?? "smtp.gmail.com";
        var smtpPort = int.Parse(_config["Smtp:Port"] ?? "587");
        var smtpUsername = _config["Smtp:Username"] ?? "";
        var smtpPassword = _config["Smtp:Password"] ?? "";
        var fromEmail = _config["Smtp:FromEmail"] ?? smtpUsername;
        var fromName = _config["Smtp:FromName"] ?? "MIANE";

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = $"MIANE — Mã xác minh: {otpCode}";

        var bodyBuilder = new BodyBuilder
        {
            HtmlBody = BuildOtpEmailHtml(otpCode)
        };
        message.Body = bodyBuilder.ToMessageBody();

        using var client = new SmtpClient();
        try
        {
            await client.ConnectAsync(smtpHost, smtpPort, SecureSocketOptions.StartTls);
            await client.AuthenticateAsync(smtpUsername, smtpPassword);
            await client.SendAsync(message);
            _logger.LogInformation("OTP email sent successfully to {Email}", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send OTP email to {Email} via SMTP. Fallback to Console/Log for Local Development.", toEmail);
            _logger.LogWarning("=================================================");
            _logger.LogWarning("DEV OTP CODE FOR {Email}: {Otp}", toEmail, otpCode);
            _logger.LogWarning("=================================================");
            
            // In development, do not block registration flow when SMTP fails.
            var isDevelopment = string.Equals(Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"), "Development", StringComparison.OrdinalIgnoreCase);
            if (!isDevelopment)
            {
                throw new InvalidOperationException("Không thể gửi email xác minh. Vui lòng thử lại sau.");
            }
        }
        finally
        {
            try
            {
                if (client.IsConnected)
                {
                    await client.DisconnectAsync(true);
                }
            }
            catch {}
        }
    }

    private static string BuildOtpEmailHtml(string otpCode)
    {
        var digits = otpCode.ToCharArray();
        var digitBoxes = string.Join("", digits.Select(d =>
            $"<td style=\"width:48px;height:56px;text-align:center;font-size:28px;font-weight:700;font-family:'SF Mono',Consolas,monospace;color:#0D2C54;background:#F0F4F8;border-radius:12px;border:2px solid #E2E8F0;letter-spacing:0;\">{d}</td>"
        ));

        return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""UTF-8""></head>
<body style=""margin:0;padding:0;background:#F8F9FA;font-family:'Be Vietnam Pro','Segoe UI',Roboto,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background:#F8F9FA;padding:40px 0;"">
<tr><td align=""center"">
<table width=""440"" cellpadding=""0"" cellspacing=""0"" style=""background:#FFFFFF;border-radius:24px;box-shadow:0 4px 24px rgba(0,0,0,0.06);overflow:hidden;"">
  <!-- Header -->
  <tr>
    <td style=""background:linear-gradient(135deg,#0D2C54,#4A90E2);padding:32px 32px 24px;text-align:center;"">
      <div style=""width:48px;height:48px;margin:0 auto 12px;background:rgba(255,255,255,0.15);border-radius:50%;line-height:48px;font-size:24px;"">🛫</div>
      <h1 style=""margin:0;color:#FFFFFF;font-size:22px;font-weight:700;letter-spacing:-0.5px;"">Xác minh email của bạn</h1>
    </td>
  </tr>
  <!-- Body -->
  <tr>
    <td style=""padding:32px;"">
      <p style=""margin:0 0 8px;color:#64748B;font-size:14px;line-height:1.6;"">Xin chào,</p>
      <p style=""margin:0 0 24px;color:#64748B;font-size:14px;line-height:1.6;"">Đây là mã xác minh để hoàn tất đăng ký tài khoản MIANE của bạn:</p>
      <!-- OTP Boxes -->
      <table cellpadding=""0"" cellspacing=""6"" style=""margin:0 auto 24px;"">
        <tr>{digitBoxes}</tr>
      </table>
      <p style=""margin:0 0 8px;color:#94A3B8;font-size:13px;text-align:center;"">Mã có hiệu lực trong <strong style=""color:#0D2C54;"">5 phút</strong></p>
      <hr style=""border:none;border-top:1px solid #F1F5F9;margin:24px 0;""/>
      <p style=""margin:0;color:#CBD5E1;font-size:12px;line-height:1.5;"">Nếu bạn không yêu cầu mã này, hãy bỏ qua email này. Không ai có thể truy cập tài khoản của bạn nếu không có mã này.</p>
    </td>
  </tr>
  <!-- Footer -->
  <tr>
    <td style=""background:#F8FAFC;padding:16px 32px;text-align:center;"">
      <p style=""margin:0;color:#94A3B8;font-size:11px;"">© 2026 MIANE — Đồng hành cùng chuyến đi của bạn</p>
    </td>
  </tr>
</table>
</td></tr>
</table>
</body>
</html>";
    }
}
