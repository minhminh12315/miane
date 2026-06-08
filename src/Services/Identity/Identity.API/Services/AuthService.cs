using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Identity; 
using Identity.API.Data;
using Identity.API.Models;
using Identity.API.Models.Auth;
using BuildingBlocks.Caching;
using Microsoft.Extensions.Logging;


namespace Identity.API.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserManager<User> _userManager;
        private readonly ICacheService _cacheService;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;

        private readonly ILogger<AuthService> _logger;

        public AuthService(UserManager<User> userManager, ICacheService cacheService, IConfiguration config, IEmailService emailService, ILogger<AuthService> logger)
        {
            _userManager = userManager;
            _cacheService = cacheService;
            _config = config;
            _emailService = emailService;
            _logger = logger;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser is not null)
            {
                throw new InvalidOperationException("A user with this email already exists.");
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
            _logger.LogInformation("[SendOtp] Generated OTP {OtpCode} for {Email}", otpCode, request.Email);

            // Store OTP + registration data in Redis with 5-minute TTL
            var cacheKey = $"reg_otp_{request.Email.ToLowerInvariant()}";
            var cacheData = new RegistrationOtpData
            {
                OtpCode = otpCode,
                Email = request.Email,
                Password = request.Password,
                FullName = request.FullName,
                AvatarUrl = request.AvatarUrl,
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
            var cacheKey = $"reg_otp_{email.ToLowerInvariant()}";
            var cachedData = await _cacheService.GetAsync<RegistrationOtpData>(cacheKey);

            if (cachedData is null)
            {
                throw new InvalidOperationException("Mã OTP đã hết hạn hoặc không tồn tại. Vui lòng yêu cầu mã mới.");
            }

            if (cachedData.OtpCode != otpCode)
            {
                throw new InvalidOperationException("Mã OTP không chính xác.");
            }

            // OTP is valid — create the user
            var existingUser = await _userManager.FindByEmailAsync(cachedData.Email);
            if (existingUser is not null)
            {
                throw new InvalidOperationException("Email này đã được đăng ký.");
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

            var result = await _userManager.CreateAsync(user, cachedData.Password);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));
            }

            // Remove OTP from cache
            await _cacheService.RemoveAsync(cacheKey);

            return await CreateAuthResponseAsync(user);
        }

        public async Task<AuthResponse?> LoginAsync(LoginRequest request) 
        {
            // 1. Find User by Email and check if active
            var user = await _userManager.FindByEmailAsync(request.Email);
            if(user == null || !user.IsActive) return null;

            // 2. Validate password
            var isPasswordValid = await _userManager.CheckPasswordAsync(user, request.Password);
            if (!isPasswordValid) return null;

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

        public async Task LogoutAsync(string userId)
        {
            await _cacheService.RemoveAsync($"session_{userId}");
        }
    }

    /// <summary>
    /// Internal data structure for storing registration + OTP in Redis cache.
    /// </summary>
    internal class RegistrationOtpData
    {
        public string OtpCode { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
