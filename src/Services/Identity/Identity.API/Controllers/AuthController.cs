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
                return Unauthorized(new { message = "Email or password is incorrect" });

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

        [Authorize]
        [HttpGet("validate")]
        public async Task<IActionResult> ValidateToken()
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
                return Unauthorized(new { message = "Invalid token subject" });
            }

            var user = await _userManager.FindByIdAsync(parsedUserId.ToString());
            if (user == null || !user.IsActive)
            {
                return Unauthorized(new { message = "User not found or inactive" });
            }

            var roles = await _userManager.GetRolesAsync(user);

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                roles
            });
        }

    }
}
