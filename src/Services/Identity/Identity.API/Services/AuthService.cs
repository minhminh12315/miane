using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Identity; 
using Identity.API.Data;
using Identity.API.Models;
using Identity.API.Models.Auth;
using BuildingBlocks.Caching;
using Microsoft.Extensions.Logging;
using Google.Apis.Auth;


namespace Identity.API.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserManager<User> _userManager;
        private readonly ICacheService _cacheService;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;
        private readonly IHostEnvironment _environment;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            UserManager<User> userManager,
            ICacheService cacheService,
            IConfiguration config,
            IEmailService emailService,
            IHostEnvironment environment,
            ILogger<AuthService> logger)
        {
            _userManager = userManager;
            _cacheService = cacheService;
            _config = config;
            _emailService = emailService;
            _environment = environment;
            _logger = logger;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            if (!_environment.IsDevelopment())
            {
                throw new InvalidOperationException(
                    "Đăng ký trực tiếp đã bị tắt. Vui lòng dùng luồng xác minh OTP.");
            }

            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser is not null)
            {
                throw new InvalidOperationException("Email này đã được đăng ký.");
            }

            var user = new User
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                AvatarUrl = request.AvatarUrl,
                EmailConfirmed = true,
                IsActive = true,
                IsEmployee = false
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));
            }

            return await CreateAuthResponseAsync(user);
        }

        public async Task SendRegistrationOtpAsync(RegisterRequest request)
        {
            _logger.LogInformation("[SendOtp] Started OTP process for email: {Email}", request.Email);

            // Validate: email must not already exist
            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser is not null)
            {
                _logger.LogWarning("[SendOtp] Registration failed: Email {Email} is already registered.", request.Email);
                throw new InvalidOperationException("Email này đã được đăng ký.");
            }

            // Validate password using Identity's password validator
            var tempUser = new User { UserName = request.Email, Email = request.Email };
            foreach (var validator in _userManager.PasswordValidators)
            {
                var passwordResult = await validator.ValidateAsync(_userManager, tempUser, request.Password);
                if (!passwordResult.Succeeded)
                {
                    var errors = string.Join("; ", passwordResult.Errors.Select(e => e.Description));
                    _logger.LogWarning("[SendOtp] Password validation failed for {Email}: {Errors}", request.Email, errors);
                    throw new InvalidOperationException(errors);
                }
            }

            // Generate 6-digit OTP
            var otpCode = RandomNumberGenerator.GetInt32(100000, 999999).ToString();
            _logger.LogInformation("[SendOtp] Generated OTP for {Email}", request.Email);

            // Store OTP + hashed password (never plaintext) in Redis with 5-minute TTL
            var passwordHasher = new PasswordHasher<User>();
            var cacheKey = $"reg_otp_{request.Email.ToLowerInvariant()}";
            var cacheData = new RegistrationOtpData
            {
                OtpCode = otpCode,
                Email = request.Email,
                PasswordHash = passwordHasher.HashPassword(tempUser, request.Password),
                FullName = request.FullName,
                AvatarUrl = request.AvatarUrl,
                FailedAttempts = 0,
                CreatedAt = DateTime.UtcNow
            };
            
            try
            {
                await _cacheService.SetAsync(cacheKey, cacheData, TimeSpan.FromMinutes(5));
                _logger.LogInformation("[SendOtp] Successfully saved OTP to Redis for {Email}", request.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[SendOtp] Failed to save OTP to Redis for {Email}", request.Email);
                throw;
            }

            // Send OTP email
            try
            {
                _logger.LogInformation("[SendOtp] Attempting to send OTP email to {Email}...", request.Email);
                await _emailService.SendOtpAsync(request.Email, otpCode);
                _logger.LogInformation("[SendOtp] OTP email process completed for {Email}", request.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[SendOtp] Error occurred while sending email to {Email}", request.Email);
                throw;
            }
        }

        public async Task<AuthResponse> VerifyRegistrationOtpAsync(string email, string otpCode)
        {
            const int maxOtpAttempts = 5;
            var cacheKey = $"reg_otp_{email.ToLowerInvariant()}";
            var cachedData = await _cacheService.GetAsync<RegistrationOtpData>(cacheKey);

            if (cachedData is null)
            {
                throw new InvalidOperationException("Mã OTP đã hết hạn hoặc không tồn tại. Vui lòng yêu cầu mã mới.");
            }

            if (cachedData.FailedAttempts >= maxOtpAttempts)
            {
                await _cacheService.RemoveAsync(cacheKey);
                throw new InvalidOperationException("Đã nhập sai OTP quá nhiều lần. Vui lòng yêu cầu mã mới.");
            }

            if (!SecureEquals(cachedData.OtpCode, otpCode))
            {
                cachedData.FailedAttempts++;
                if (cachedData.FailedAttempts >= maxOtpAttempts)
                {
                    await _cacheService.RemoveAsync(cacheKey);
                    throw new InvalidOperationException("Đã nhập sai OTP quá nhiều lần. Vui lòng yêu cầu mã mới.");
                }

                var remainingTtl = TimeSpan.FromMinutes(5) - (DateTime.UtcNow - cachedData.CreatedAt);
                if (remainingTtl < TimeSpan.FromSeconds(30))
                {
                    remainingTtl = TimeSpan.FromSeconds(30);
                }

                await _cacheService.SetAsync(cacheKey, cachedData, remainingTtl);
                throw new InvalidOperationException("Mã OTP không chính xác.");
            }

            // OTP is valid — create the user with the pre-hashed password
            var existingUser = await _userManager.FindByEmailAsync(cachedData.Email);
            if (existingUser is not null)
            {
                throw new InvalidOperationException("Email này đã được đăng ký.");
            }

            if (string.IsNullOrWhiteSpace(cachedData.PasswordHash))
            {
                await _cacheService.RemoveAsync(cacheKey);
                throw new InvalidOperationException("Phiên đăng ký không hợp lệ. Vui lòng yêu cầu mã mới.");
            }

            var user = new User
            {
                UserName = cachedData.Email,
                Email = cachedData.Email,
                FullName = cachedData.FullName,
                AvatarUrl = cachedData.AvatarUrl,
                EmailConfirmed = true,
                IsActive = true,
                IsEmployee = false
            };

            var result = await _userManager.CreateAsync(user);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));
            }

            user.PasswordHash = cachedData.PasswordHash;
            await _userManager.UpdateAsync(user);

            await _cacheService.RemoveAsync(cacheKey);

            return await CreateAuthResponseAsync(user);
        }

        public async Task SendPasswordResetOtpAsync(ForgotPasswordRequest request)
        {
            var email = NormalizeEmail(request.Email);
            _logger.LogInformation("[ForgotPassword] Password reset OTP requested for {Email}", email);

            var user = await _userManager.FindByEmailAsync(email);
            if (user is null || !user.IsActive)
            {
                _logger.LogInformation(
                    "[ForgotPassword] Ignoring password reset request for unknown or inactive email {Email}",
                    email);
                return;
            }

            var otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
            var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
            var cacheKey = BuildPasswordResetOtpCacheKey(email);
            var cacheData = new PasswordResetOtpData
            {
                UserId = user.Id,
                Email = email,
                OtpCode = otpCode,
                ResetToken = resetToken,
                CreatedAt = DateTime.UtcNow
            };

            await _cacheService.SetAsync(cacheKey, cacheData, TimeSpan.FromMinutes(5));
            await _emailService.SendPasswordResetOtpAsync(user.Email ?? email, otpCode);
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var email = NormalizeEmail(request.Email);
            var cacheKey = BuildPasswordResetOtpCacheKey(email);
            var cachedData = await _cacheService.GetAsync<PasswordResetOtpData>(cacheKey);

            if (cachedData is null)
            {
                throw new InvalidOperationException("Mã đặt lại mật khẩu đã hết hạn hoặc không tồn tại. Vui lòng yêu cầu mã mới.");
            }

            if (!SecureEquals(cachedData.OtpCode, request.OtpCode))
            {
                cachedData.FailedAttempts++;
                if (cachedData.FailedAttempts >= 5)
                {
                    await _cacheService.RemoveAsync(cacheKey);
                    throw new InvalidOperationException("Đã nhập sai mã quá nhiều lần. Vui lòng yêu cầu mã mới.");
                }

                var remainingTtl = TimeSpan.FromMinutes(5) - (DateTime.UtcNow - cachedData.CreatedAt);
                if (remainingTtl < TimeSpan.FromSeconds(30))
                {
                    remainingTtl = TimeSpan.FromSeconds(30);
                }

                await _cacheService.SetAsync(cacheKey, cachedData, remainingTtl);
                throw new InvalidOperationException("Mã đặt lại mật khẩu không chính xác.");
            }

            var user = await _userManager.FindByIdAsync(cachedData.UserId.ToString());
            if (user is null ||
                !user.IsActive ||
                NormalizeEmail(user.Email ?? string.Empty) != cachedData.Email)
            {
                await _cacheService.RemoveAsync(cacheKey);
                throw new InvalidOperationException("Mã đặt lại mật khẩu không hợp lệ. Vui lòng yêu cầu mã mới.");
            }

            var result = await _userManager.ResetPasswordAsync(user, cachedData.ResetToken, request.NewPassword);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));
            }

            await _cacheService.RemoveAsync(cacheKey);
            await _cacheService.RemoveAsync($"session_{user.Id}");
        }

        public async Task<AuthResponse?> LoginAsync(LoginRequest request) 
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null || !user.IsActive) return null;

            if (await _userManager.IsLockedOutAsync(user))
            {
                _logger.LogWarning("Login blocked for locked-out user {Email}", request.Email);
                return null;
            }

            var isPasswordValid = await _userManager.CheckPasswordAsync(user, request.Password);
            if (!isPasswordValid)
            {
                await _userManager.AccessFailedAsync(user);
                return null;
            }

            await _userManager.ResetAccessFailedCountAsync(user);
            return await CreateAuthResponseAsync(user);
        }

        public async Task<AuthResponse> LoginGoogleAsync(GoogleLoginRequest request)
        {
            string email = string.Empty;
            string fullName = string.Empty;
            string? avatarUrl = null;

            // Mock Google login is Development-only and requires an explicit
            // mock token or Google:BypassValidation=true. Never match "mock"
            // as a substring of arbitrary tokens.
            var allowDevMock = _environment.IsDevelopment()
                && (request.IdToken == "mock_google_token"
                    || _config.GetValue<bool>("Google:BypassValidation", false));

            if (allowDevMock && request.IdToken == "mock_google_token")
            {
                email = "google_test@miane.com";
                fullName = "Google Tester";
                avatarUrl = "https://lh3.googleusercontent.com/a/mock-avatar-url";
            }
            else
            {
                try
                {
                    var validationSettings = new GoogleJsonWebSignature.ValidationSettings();
                    var googleClientId = _config["Google:ClientId"];
                    if (!string.IsNullOrEmpty(googleClientId))
                    {
                        validationSettings.Audience = new[] { googleClientId };
                    }

                    var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, validationSettings);
                    email = payload.Email;
                    fullName = payload.Name ?? payload.GivenName ?? "Google User";
                    avatarUrl = payload.Picture;
                }
                catch (Exception ex)
                {
                    if (allowDevMock && _config.GetValue<bool>("Google:BypassValidation", false))
                    {
                        _logger.LogWarning(ex,
                            "Google token validation failed; using Development BypassValidation mock user.");
                        email = "google_test@miane.com";
                        fullName = "Google Tester";
                        avatarUrl = "https://lh3.googleusercontent.com/a/mock-avatar-url";
                    }
                    else
                    {
                        _logger.LogError(ex, "Failed to validate Google ID Token.");
                        throw new InvalidOperationException(
                            "Xác thực tài khoản Google không hợp lệ hoặc đã hết hạn.", ex);
                    }
                }
            }

            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
            {
                user = new User
                {
                    UserName = email,
                    Email = email,
                    FullName = fullName,
                    AvatarUrl = avatarUrl,
                    EmailConfirmed = true,
                    IsActive = true,
                    IsEmployee = false,
                    UserTier = 0
                };

                var createResult = await _userManager.CreateAsync(user);
                if (!createResult.Succeeded)
                {
                    throw new InvalidOperationException($"Không thể tạo tài khoản từ Google: {string.Join("; ", createResult.Errors.Select(e => e.Description))}");
                }
            }
            else
            {
                if (!user.IsActive)
                {
                    throw new InvalidOperationException("Tài khoản của bạn đã bị khóa.");
                }

                bool updated = false;
                if (string.IsNullOrEmpty(user.FullName) && !string.IsNullOrEmpty(fullName))
                {
                    user.FullName = fullName;
                    updated = true;
                }
                if (string.IsNullOrEmpty(user.AvatarUrl) && !string.IsNullOrEmpty(avatarUrl))
                {
                    user.AvatarUrl = avatarUrl;
                    updated = true;
                }
                if (updated)
                {
                    await _userManager.UpdateAsync(user);
                }
            }

            return await CreateAuthResponseAsync(user);
        }

        private async Task<AuthResponse> CreateAuthResponseAsync(User user)
        {
            var userClaims = await _userManager.GetClaimsAsync(user);
            var permissions = userClaims.Where(c => c.Type == "Permission").Select(c => c.Value).ToList();
            var roles = (await _userManager.GetRolesAsync(user)).ToList();
            var accessToken = GenerateJwtToken(user, permissions, roles);
            var refreshToken = Guid.NewGuid().ToString(); 

            await _cacheService.SetAsync($"session_{user.Id}", refreshToken, TimeSpan.FromDays(7));
            await _cacheService.SetAsync($"refresh_{refreshToken}", user.Id.ToString(), TimeSpan.FromDays(7));

            return new AuthResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                TokenType = "Bearer",
                ExpiresIn = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_config["Jwt:DurationInMinutes"])),
                User = new AuthUserResponse
                {
                    Id = user.Id,
                    Email = user.Email,
                    FullName = user.FullName,
                    AvatarUrl = user.AvatarUrl,
                    IsEmployee = user.IsEmployee
                },
                Permissions = permissions,
                Roles = roles
            };
        }

        private string GenerateJwtToken(User user, List<string> permissions, List<string> roles)
        {
            // 1. Create Claims (infomations in Payload by Token)
            var claims = new List<Claim>
            {
                // Standard JWT claims
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email!),
                new Claim(ClaimTypes.Email, user.Email!),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),

                // Custom informations for Frontend (make Next.js doesn't need to recall API get name)
                new Claim("FullName", user.FullName),
                new Claim("IsEmployee", user.IsEmployee.ToString()),
                new Claim("UserTier", user.UserTier.ToString())
            };

            foreach (var permission in permissions)
            {
                claims.Add(new Claim("Permission", permission));
            }

            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            // 3. Get Secret Key from appsettings.json and hash it
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // 4. Proceed to "Wrap" Token
            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(Convert.ToDouble(_config["Jwt:DurationInMinutes"])),
                signingCredentials: creds
            );

            // 5. Export hash string (Header.Payload.Signature)
            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public async Task<AuthResponse> UpgradeToProAsync(Guid userId, UpgradeProRequest? purchase = null)
        {
            ValidateProPurchaseEvidence(purchase);

            var user = await _userManager.FindByIdAsync(userId.ToString())
                ?? throw new InvalidOperationException("Không tìm thấy người dùng.");

            if (user.UserTier != 1)
            {
                user.UserTier = 1;
                await _userManager.UpdateAsync(user);
            }

            // Reissue tokens so the UserTier claim (and the X-User-Tier header
            // the Gateway forwards from it) reflects Pro immediately, without
            // requiring the client to log out and back in.
            return await CreateAuthResponseAsync(user);
        }

        private void ValidateProPurchaseEvidence(UpgradeProRequest? purchase)
        {
            // Development may upgrade without a receipt for StoreKit Testing /
            // simulator flows. Outside Development a non-empty store receipt is
            // required. Full App Store Server API / Play Developer API verify
            // should replace this gate before public billing ships.
            if (_environment.IsDevelopment())
            {
                return;
            }

            if (purchase is null
                || string.IsNullOrWhiteSpace(purchase.ReceiptData)
                || string.IsNullOrWhiteSpace(purchase.Platform))
            {
                throw new InvalidOperationException(
                    "Nâng cấp Pro yêu cầu bằng chứng mua hàng từ App Store / Play (receipt).");
            }

            var platform = purchase.Platform.Trim().ToLowerInvariant();
            if (platform is not ("ios" or "android"))
            {
                throw new InvalidOperationException("Platform mua hàng không hợp lệ.");
            }

            if (purchase.ReceiptData.Contains("mock", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Receipt mock không được chấp nhận ngoài Development.");
            }

            _logger.LogInformation(
                "Pro upgrade receipt accepted for verification pipeline: platform={Platform}, product={ProductId}, tx={TransactionId}, receiptLength={Length}",
                platform,
                purchase.ProductId,
                purchase.TransactionId,
                purchase.ReceiptData.Length);
        }

        public async Task LogoutAsync(string userId)
        {
            var existingRefresh = await _cacheService.GetAsync<string>($"session_{userId}");
            await _cacheService.RemoveAsync($"session_{userId}");
            if (!string.IsNullOrWhiteSpace(existingRefresh))
            {
                await _cacheService.RemoveAsync($"refresh_{existingRefresh}");
            }
        }

        public async Task<AuthResponse?> RefreshAsync(RefreshTokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.RefreshToken))
            {
                return null;
            }

            Guid userId;
            if (request.UserId is Guid explicitUserId && explicitUserId != Guid.Empty)
            {
                userId = explicitUserId;
            }
            else
            {
                var mappedUserId = await _cacheService.GetAsync<string>($"refresh_{request.RefreshToken}");
                if (string.IsNullOrWhiteSpace(mappedUserId) || !Guid.TryParse(mappedUserId, out userId))
                {
                    return null;
                }
            }

            var cachedToken = await _cacheService.GetAsync<string>($"session_{userId}");
            if (string.IsNullOrWhiteSpace(cachedToken))
            {
                return null;
            }

            var cachedBytes = Encoding.UTF8.GetBytes(cachedToken);
            var providedBytes = Encoding.UTF8.GetBytes(request.RefreshToken);
            if (cachedBytes.Length != providedBytes.Length ||
                !CryptographicOperations.FixedTimeEquals(cachedBytes, providedBytes))
            {
                return null;
            }

            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null || !user.IsActive)
            {
                await LogoutAsync(userId.ToString());
                return null;
            }

            // Rotate: drop old refresh index before issuing a new pair.
            await _cacheService.RemoveAsync($"refresh_{request.RefreshToken}");
            return await CreateAuthResponseAsync(user);
        }

        private static string NormalizeEmail(string email) =>
            email.Trim().ToLowerInvariant();

        private static string BuildPasswordResetOtpCacheKey(string email) =>
            $"password_reset_otp_{NormalizeEmail(email)}";

        private static bool SecureEquals(string expected, string provided)
        {
            var expectedBytes = Encoding.UTF8.GetBytes(expected);
            var providedBytes = Encoding.UTF8.GetBytes(provided);
            return expectedBytes.Length == providedBytes.Length &&
                   CryptographicOperations.FixedTimeEquals(expectedBytes, providedBytes);
        }
    }

    /// <summary>
    /// Internal data structure for storing registration + OTP in Redis cache.
    /// </summary>
    internal class RegistrationOtpData
    {
        public string OtpCode { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        /// <summary>ASP.NET Identity password hash — never store plaintext.</summary>
        public string PasswordHash { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public int FailedAttempts { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    internal class PasswordResetOtpData
    {
        public Guid UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string OtpCode { get; set; } = string.Empty;
        public string ResetToken { get; set; } = string.Empty;
        public int FailedAttempts { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
