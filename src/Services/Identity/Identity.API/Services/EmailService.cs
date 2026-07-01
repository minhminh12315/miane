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
        var smtpHost = GetSmtpSetting("Host", "smtp.gmail.com");
        var smtpPortValue = GetSmtpSetting("Port", "587");
        if (!int.TryParse(smtpPortValue, out var smtpPort))
        {
            throw new InvalidOperationException("Smtp:Port is invalid.");
        }

        var smtpUsername = GetSmtpSetting("Username");
        var smtpPassword = GetSmtpSetting("Password");
        var fromEmail = GetSmtpSetting("FromEmail", smtpUsername);
        var fromName = GetSmtpSetting("FromName", "MIANE");

        EnsureSmtpConfigured(smtpHost, smtpUsername, smtpPassword, fromEmail);

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
            _logger.LogError(ex, "Failed to send OTP email to {Email} via SMTP.", toEmail);
            throw new InvalidOperationException("Khong the gui email xac minh. Vui long kiem tra cau hinh SMTP hoac thu lai sau.", ex);
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

    private string GetSmtpSetting(string key, string? defaultValue = null)
    {
        var fullKey = $"Smtp:{key}";

        if (_config is IConfigurationRoot root)
        {
            foreach (var provider in root.Providers.Reverse())
            {
                if (provider.TryGet(fullKey, out var value) && !string.IsNullOrWhiteSpace(value))
                {
                    return value.Trim();
                }
            }
        }

        var configuredValue = _config[fullKey];
        if (!string.IsNullOrWhiteSpace(configuredValue))
        {
            return configuredValue.Trim();
        }

        return defaultValue?.Trim() ?? string.Empty;
    }

    private static void EnsureSmtpConfigured(string smtpHost, string smtpUsername, string smtpPassword, string fromEmail)
    {
        var missing = new List<string>();

        if (string.IsNullOrWhiteSpace(smtpHost)) missing.Add("Smtp:Host");
        if (string.IsNullOrWhiteSpace(smtpUsername)) missing.Add("Smtp:Username");
        if (string.IsNullOrWhiteSpace(smtpPassword)) missing.Add("Smtp:Password");
        if (string.IsNullOrWhiteSpace(fromEmail)) missing.Add("Smtp:FromEmail");

        if (missing.Count > 0)
        {
            throw new InvalidOperationException($"SMTP is not configured. Missing: {string.Join(", ", missing)}.");
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
