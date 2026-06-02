using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Identity; 
using Identity.API.Data;
using Identity.API.Models;
using Identity.API.Models.Auth;
using BuildingBlocks.Caching;

namespace Identity.API.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserManager<User> _userManager;
        private readonly ICacheService _cacheService;
        private readonly IConfiguration _config; 

        public AuthService(UserManager<User> userManager, ICacheService cacheService, IConfiguration config)
        {
            _userManager = userManager;
            _cacheService = cacheService;
            _config = config;
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
                new Claim("IsEmployee", user.IsEmployee.ToString())
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
}
