using Identity.API.Models;
using Microsoft.AspNetCore.Identity;

namespace Identity.API.Data;

public static class IdentitySeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        var userManager = services.GetRequiredService<UserManager<User>>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        var environment = services.GetRequiredService<IHostEnvironment>();

        var roles = new[] { "Admin", "Employee" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole<Guid>(role));
            }
        }

        var adminEmail = "admin@Miane.local";
        var employeeEmail = "staff@Miane.local";

        if (await userManager.FindByEmailAsync(adminEmail) is null)
        {
            var admin = new User
            {
                UserName = adminEmail,
                Email = adminEmail,
                FullName = "System Admin",
                IsEmployee = true,
                EmployeeId = "EMP0001",
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(admin, "Admin@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(admin, "Admin");
                await userManager.AddClaimsAsync(admin, new[]
                {
                    new System.Security.Claims.Claim("Permission", "users.read"),
                    new System.Security.Claims.Claim("Permission", "users.write"),
                    new System.Security.Claims.Claim("Permission", "dashboard.view")
                });
            }
        }

        if (await userManager.FindByEmailAsync(employeeEmail) is null)
        {
            var staff = new User
            {
                UserName = employeeEmail,
                Email = employeeEmail,
                FullName = "Demo Staff",
                IsEmployee = true,
                EmployeeId = "EMP0002",
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(staff, "Staff@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(staff, "Employee");
                await userManager.AddClaimAsync(staff,
                    new System.Security.Claims.Claim("Permission", "dashboard.view"));
            }
        }

        if (environment.IsDevelopment())
        {
            await SeedDemoTripUsersAsync(userManager);
        }
    }

    private static async Task SeedDemoTripUsersAsync(UserManager<User> userManager)
    {
        foreach (var demoUser in DemoTripSeedData.Users)
        {
            if (await userManager.FindByEmailAsync(demoUser.Email) is not null)
            {
                continue;
            }

            var user = new User
            {
                Id = demoUser.Id,
                UserName = demoUser.Email,
                Email = demoUser.Email,
                FullName = demoUser.FullName,
                EmailConfirmed = true,
                IsActive = true,
                IsEmployee = false,
                UserTier = 0
            };

            await userManager.CreateAsync(user, DemoTripSeedData.Password);
        }
    }
}
