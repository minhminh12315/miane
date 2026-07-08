using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using Identity.API.Models;

namespace Identity.API.Controllers
{
    /// <summary>
    /// Admin-only user management: list/create/update/activate/deactivate any user.
    /// Requires the "Admin" role (seeded by IdentitySeeder).
    /// </summary>
    [ApiController]
    [Route("users")]
    [Authorize(Roles = "Admin")]
    public class UsersController : ControllerBase
    {
        private readonly UserManager<User> _userManager;

        public UsersController(UserManager<User> userManager)
        {
            _userManager = userManager;
        }

        [HttpGet]
        public async Task<IActionResult> ListUsers(CancellationToken ct)
        {
            var users = await _userManager.Users
                .OrderByDescending(u => u.CreateAt)
                .ToListAsync(ct);

            var result = new List<AdminUserResponse>();
            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                result.Add(new AdminUserResponse(
                    user.Id, user.FullName, user.Email!, user.UserTier, user.IsActive, user.IsEmployee, user.CreateAt, roles));
            }

            return Ok(result);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetUser(Guid id)
        {
            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user is null) return NotFound(new { message = "User not found." });

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(new AdminUserResponse(
                user.Id, user.FullName, user.Email!, user.UserTier, user.IsActive, user.IsEmployee, user.CreateAt, roles));
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] AdminCreateUserRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName) || string.IsNullOrWhiteSpace(request.Email))
                return BadRequest(new { message = "FullName and Email are required." });

            if (await _userManager.FindByEmailAsync(request.Email) is not null)
                return BadRequest(new { message = "A user with this email already exists." });

            var user = new User
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                UserTier = request.UserTier,
                IsActive = request.IsActive,
                EmailConfirmed = true,
                IsEmployee = request.IsAdmin
            };

            // Admin-created accounts have no self-serve invite flow yet, so we
            // generate a temporary password and hand it back once so the admin
            // can share it out-of-band. The user should change it on first login.
            var tempPassword = $"Temp{RandomNumberGenerator.GetInt32(100000, 999999)}";
            var result = await _userManager.CreateAsync(user, tempPassword);
            if (!result.Succeeded)
                return BadRequest(new { message = string.Join("; ", result.Errors.Select(e => e.Description)) });

            if (request.IsAdmin)
                await _userManager.AddToRoleAsync(user, "Admin");

            return Created($"/users/{user.Id}", new AdminUserCreatedResponse(
                user.Id, user.FullName, user.Email!, user.UserTier, user.IsActive, tempPassword, request.IsAdmin));
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] AdminUpdateUserRequest request)
        {
            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user is null) return NotFound(new { message = "User not found." });

            user.FullName = request.FullName;
            user.UserTier = request.UserTier;

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
                return BadRequest(new { message = string.Join("; ", result.Errors.Select(e => e.Description)) });

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(new AdminUserResponse(
                user.Id, user.FullName, user.Email!, user.UserTier, user.IsActive, user.IsEmployee, user.CreateAt, roles));
        }

        [HttpPut("{id:guid}/status")]
        public async Task<IActionResult> SetStatus(Guid id, [FromBody] AdminSetStatusRequest request)
        {
            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user is null) return NotFound(new { message = "User not found." });

            user.IsActive = request.IsActive;
            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
                return BadRequest(new { message = string.Join("; ", result.Errors.Select(e => e.Description)) });

            return Ok(new { id = user.Id, isActive = user.IsActive });
        }
    }

    public sealed record AdminUserResponse(
        Guid Id, string FullName, string Email, int UserTier, bool IsActive, bool IsEmployee, DateTime CreateAt, IList<string> Roles);

    public sealed record AdminUserCreatedResponse(
        Guid Id, string FullName, string Email, int UserTier, bool IsActive, string TempPassword, bool IsAdmin);

    public sealed record AdminCreateUserRequest(string FullName, string Email, int UserTier, bool IsActive, bool IsAdmin);

    public sealed record AdminUpdateUserRequest(string FullName, int UserTier);

    public sealed record AdminSetStatusRequest(bool IsActive);
}
