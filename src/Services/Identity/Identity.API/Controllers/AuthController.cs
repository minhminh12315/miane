using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Identity.API.Models;
using Identity.API.Models.Auth;
using Identity.API.Services;


namespace Identity.API.Controllers
{
    [ApiController]
    [Route("auth")]
    public class AuthController : ControllerBase
    {
        private const long MaxAvatarUploadBytes = 5 * 1024 * 1024;
        private static readonly HashSet<string> AllowedAvatarExtensions = new(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp",
            ".heic"
        };

        private readonly IAuthService _authService;
        private readonly IWebHostEnvironment _env;
        private readonly UserManager<User> _userManager;
        public AuthController(IAuthService authService, IWebHostEnvironment env, UserManager<User> userManager)
        {
            _authService = authService;
            _env = env;
            _userManager = userManager;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            try
            {
                var response = await _authService.RegisterAsync(request);
                return Created("/auth/me", response);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("register/send-otp")]
        public async Task<IActionResult> SendRegistrationOtp([FromBody] RegisterRequest request)
        {
            try
            {
                await _authService.SendRegistrationOtpAsync(request);
                return Ok(new { message = "Mã xác minh đã được gửi đến email của bạn." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("register/verify-otp")]
        public async Task<IActionResult> VerifyRegistrationOtp([FromBody] VerifyOtpRequest request)
        {
            try
            {
                var response = await _authService.VerifyRegistrationOtpAsync(request.Email, request.OtpCode);

                var accessCookieOptions = new CookieOptions
                {
                    HttpOnly = true,
                    Secure = !_env.IsDevelopment(),
                    SameSite = SameSiteMode.Strict,
                    Expires = response.ExpiresIn
                };

                var refreshCookieOptions = new CookieOptions
                {
                    HttpOnly = true,
                    Secure = !_env.IsDevelopment(),
                    SameSite = SameSiteMode.Strict,
                    Expires = DateTime.UtcNow.AddDays(7)
                };

                Response.Cookies.Append("access_token", response.AccessToken, accessCookieOptions);
                Response.Cookies.Append("refresh_token", response.RefreshToken, refreshCookieOptions);
                return Created("/auth/me", response);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var response = await _authService.LoginAsync(request);

            if (response == null)
                return Unauthorized(new { message = "Email hoặc mật khẩu không đúng." });

            var accessCookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = !_env.IsDevelopment(),
                SameSite = SameSiteMode.Strict,
                Expires = response.ExpiresIn
            };

            var refreshCookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = !_env.IsDevelopment(),
                SameSite = SameSiteMode.Strict,
                Expires = DateTime.UtcNow.AddDays(7)
            };

            Response.Cookies.Append("access_token", response.AccessToken, accessCookieOptions);
            Response.Cookies.Append("refresh_token", response.RefreshToken, refreshCookieOptions);
            return Ok(response);

        }

        [HttpPost("google")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
        {
            try
            {
                var response = await _authService.LoginGoogleAsync(request);

                var accessCookieOptions = new CookieOptions
                {
                    HttpOnly = true,
                    Secure = !_env.IsDevelopment(),
                    SameSite = SameSiteMode.Strict,
                    Expires = response.ExpiresIn
                };

                var refreshCookieOptions = new CookieOptions
                {
                    HttpOnly = true,
                    Secure = !_env.IsDevelopment(),
                    SameSite = SameSiteMode.Strict,
                    Expires = DateTime.UtcNow.AddDays(7)
                };

                Response.Cookies.Append("access_token", response.AccessToken, accessCookieOptions);
                Response.Cookies.Append("refresh_token", response.RefreshToken, refreshCookieOptions);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrWhiteSpace(userId))
            {
                await _authService.LogoutAsync(userId);
            }
            
            Response.Cookies.Delete("access_token");
            Response.Cookies.Delete("refresh_token");

            return NoContent();
        }

        [HttpPost("refresh")]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest request)
        {
            var response = await _authService.RefreshAsync(request);
            if (response is null)
            {
                Response.Cookies.Delete("access_token");
                Response.Cookies.Delete("refresh_token");
                return Unauthorized(new { message = "Phiên đăng nhập đã hết hạn." });
            }

            var accessCookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = !_env.IsDevelopment(),
                SameSite = SameSiteMode.Strict,
                Expires = response.ExpiresIn
            };
            var refreshCookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = !_env.IsDevelopment(),
                SameSite = SameSiteMode.Strict,
                Expires = DateTime.UtcNow.AddDays(7)
            };

            Response.Cookies.Append("access_token", response.AccessToken, accessCookieOptions);
            Response.Cookies.Append("refresh_token", response.RefreshToken, refreshCookieOptions);
            return Ok(response);
        }

        /// <summary>
        /// Upgrades the authenticated user to MIANE Pro after a client-side
        /// StoreKit/Play Billing purchase completes.
        /// </summary>
        /// <remarks>
        /// DEV/TESTING NOTE: this trusts the client purchase result as-is —
        /// there is no server-side App Store/Play receipt verification here.
        /// Fine for StoreKit Testing in Simulator; before shipping this must
        /// validate the receipt via the App Store Server API (iOS) / Play
        /// Developer API (Android) before flipping UserTier.
        /// </remarks>
        [Authorize]
        [HttpPost("upgrade-pro")]
        public async Task<IActionResult> UpgradeToPro()
        {
            var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            {
                return Unauthorized(new { message = "Token không hợp lệ." });
            }

            var response = await _authService.UpgradeToProAsync(parsedUserId);

            var accessCookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = !_env.IsDevelopment(),
                SameSite = SameSiteMode.Strict,
                Expires = response.ExpiresIn
            };

            var refreshCookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = !_env.IsDevelopment(),
                SameSite = SameSiteMode.Strict,
                Expires = DateTime.UtcNow.AddDays(7)
            };

            Response.Cookies.Append("access_token", response.AccessToken, accessCookieOptions);
            Response.Cookies.Append("refresh_token", response.RefreshToken, refreshCookieOptions);
            return Ok(response);
        }

        [Authorize]
        [HttpGet("validate")]
        public async Task<IActionResult> ValidateToken()
        {
            var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            {
                return Unauthorized(new { message = "Token không hợp lệ." });
            }

            var user = await _userManager.FindByIdAsync(parsedUserId.ToString());
            if (user == null || !user.IsActive)
            {
                return Unauthorized(new { message = "Không tìm thấy người dùng hoặc tài khoản đã bị vô hiệu hóa." });
            }

            var roles = await _userManager.GetRolesAsync(user);
            var permissions = User.Claims
                .Where(claim => claim.Type == "Permission")
                .Select(claim => claim.Value)
                .Distinct()
                .ToList();

            return Ok(new TokenValidationResponse
            {
                IsValid = true,
                UserId = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                Roles = roles.ToList(),
                Permissions = permissions
            });
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            {
                return Unauthorized(new { message = "Token không hợp lệ." });
            }

            var user = await _userManager.FindByIdAsync(parsedUserId.ToString());
            if (user == null || !user.IsActive)
            {
                return Unauthorized(new { message = "Không tìm thấy người dùng hoặc tài khoản đã bị vô hiệu hóa." });
            }

            var roles = await _userManager.GetRolesAsync(user);

            return Ok(ToProfileResponse(user, roles));
        }

        [Authorize]
        [HttpPut("me")]
        public async Task<IActionResult> UpdateMe([FromBody] UpdateMeRequest request)
        {
            var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            {
                return Unauthorized(new { message = "Invalid token subject" });
            }

            var user = await _userManager.FindByIdAsync(parsedUserId.ToString());
            if (user == null || !user.IsActive)
            {
                return Unauthorized(new { message = "User not found or inactive" });
            }

            var fullName = request.FullName?.Trim() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(fullName))
            {
                return BadRequest(new { message = "Vui lòng nhập tên hiển thị." });
            }

            if (fullName.Length > 120)
            {
                return BadRequest(new { message = "Tên hiển thị không được vượt quá 120 ký tự." });
            }

            var avatarUrl = string.IsNullOrWhiteSpace(request.AvatarUrl)
                ? null
                : request.AvatarUrl.Trim();
            if (avatarUrl is not null)
            {
                if (avatarUrl.Length > 1000)
                {
                    return BadRequest(new { message = "Liên kết ảnh đại diện không được vượt quá 1000 ký tự." });
                }

                var isStoredAvatar = avatarUrl.StartsWith("/auth/avatars/", StringComparison.OrdinalIgnoreCase);
                if (!isStoredAvatar &&
                    (!Uri.TryCreate(avatarUrl, UriKind.Absolute, out var parsedUri) ||
                    (parsedUri.Scheme != Uri.UriSchemeHttp && parsedUri.Scheme != Uri.UriSchemeHttps)))
                {
                    return BadRequest(new { message = "Ảnh đại diện phải là URL http hoặc https hợp lệ." });
                }
            }

            var previousAvatarUrl = user.AvatarUrl;
            user.FullName = fullName;
            user.AvatarUrl = avatarUrl;

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
            {
                return BadRequest(new { message = string.Join("; ", result.Errors.Select(e => e.Description)) });
            }

            DeleteStoredAvatarIfReplaced(previousAvatarUrl, avatarUrl);

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(ToProfileResponse(user, roles));
        }

        [Authorize]
        [HttpPost("me/avatar")]
        [RequestSizeLimit(MaxAvatarUploadBytes)]
        public async Task<IActionResult> UploadAvatar([FromForm] IFormFile? file, CancellationToken ct)
        {
            var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
            {
                return Unauthorized(new { message = "Invalid token subject" });
            }

            var user = await _userManager.FindByIdAsync(parsedUserId.ToString());
            if (user == null || !user.IsActive)
            {
                return Unauthorized(new { message = "User not found or inactive" });
            }

            if (file is null || file.Length <= 0)
            {
                return BadRequest(new { message = "Vui lòng chọn ảnh đại diện." });
            }

            if (file.Length > MaxAvatarUploadBytes)
            {
                return BadRequest(new { message = "Ảnh đại diện không được vượt quá 5 MB." });
            }

            var originalFileName = Path.GetFileName(file.FileName);
            var extension = Path.GetExtension(originalFileName);
            if (string.IsNullOrWhiteSpace(extension) || !AllowedAvatarExtensions.Contains(extension))
            {
                return BadRequest(new { message = "Định dạng ảnh đại diện không được hỗ trợ." });
            }

            var storageName = $"{parsedUserId:N}-{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
            var uploadDirectory = GetAvatarUploadDirectory();
            Directory.CreateDirectory(uploadDirectory);

            var absolutePath = Path.Combine(uploadDirectory, storageName);
            await using (var stream = System.IO.File.Create(absolutePath))
            {
                await file.CopyToAsync(stream, ct);
            }

            var previousAvatarUrl = user.AvatarUrl;
            user.AvatarUrl = BuildAvatarUrl(storageName);

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
            {
                System.IO.File.Delete(absolutePath);
                return BadRequest(new { message = string.Join("; ", result.Errors.Select(e => e.Description)) });
            }

            DeleteStoredAvatarIfReplaced(previousAvatarUrl, user.AvatarUrl);

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(ToProfileResponse(user, roles));
        }

        [AllowAnonymous]
        [HttpGet("avatars/{storageName}")]
        public IActionResult GetAvatar(string storageName)
        {
            var safeStorageName = Path.GetFileName(storageName);
            if (safeStorageName != storageName)
            {
                return BadRequest(new { message = "Tên ảnh đại diện không hợp lệ." });
            }

            var absolutePath = Path.Combine(GetAvatarUploadDirectory(), safeStorageName);
            if (!System.IO.File.Exists(absolutePath))
            {
                return NotFound(new { message = "Không tìm thấy ảnh đại diện." });
            }

            return PhysicalFile(
                absolutePath,
                GuessAvatarContentType(Path.GetExtension(safeStorageName)),
                enableRangeProcessing: true);
        }

        private static object ToProfileResponse(User user, IList<string> roles) => new
        {
            id = user.Id,
            email = user.Email,
            fullName = user.FullName,
            avatarUrl = user.AvatarUrl,
            userTier = user.UserTier,
            roles
        };

        private string GetAvatarUploadDirectory() =>
            Path.Combine(_env.ContentRootPath, "uploads", "avatars");

        private static string BuildAvatarUrl(string storageName) =>
            $"/auth/avatars/{storageName}";

        private void DeleteStoredAvatarIfReplaced(string? previousAvatarUrl, string? nextAvatarUrl)
        {
            if (string.IsNullOrWhiteSpace(previousAvatarUrl) ||
                string.Equals(previousAvatarUrl, nextAvatarUrl, StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            const string marker = "/auth/avatars/";
            var index = previousAvatarUrl.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
            if (index < 0) return;

            var storageName = previousAvatarUrl[(index + marker.Length)..];
            storageName = Path.GetFileName(storageName);
            if (string.IsNullOrWhiteSpace(storageName)) return;

            var absolutePath = Path.Combine(GetAvatarUploadDirectory(), storageName);
            if (System.IO.File.Exists(absolutePath))
            {
                System.IO.File.Delete(absolutePath);
            }
        }

        private static string GuessAvatarContentType(string extension) =>
            extension.ToLowerInvariant() switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".heic" => "image/heic",
                _ => "application/octet-stream"
            };

    }

    public sealed record UpdateMeRequest(string? FullName, string? AvatarUrl);
}
