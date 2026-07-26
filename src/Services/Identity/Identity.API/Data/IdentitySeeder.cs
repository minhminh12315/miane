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
        var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("IdentitySeeder");

        var roles = new[] { "Admin", "Employee" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole<Guid>(role));
            }
        }

        // Hardcoded demo admin/staff passwords only in Development.
        // Production: set ADMIN_BOOTSTRAP_PASSWORD (and optional ADMIN_BOOTSTRAP_EMAIL)
        // on first deploy to create a single admin, then rotate.
        if (environment.IsDevelopment())
        {
            await SeedLocalAdminAsync(userManager, "admin@Miane.local", "System Admin", "EMP0001", "Admin", "Admin@123",
                new[] { "users.read", "users.write", "dashboard.view" });
            await SeedLocalAdminAsync(userManager, "staff@Miane.local", "Demo Staff", "EMP0002", "Employee", "Staff@123",
                new[] { "dashboard.view" });
            await SeedDemoTripUsersAsync(userManager);
        }
        else
        {
            var bootstrapPassword = Environment.GetEnvironmentVariable("ADMIN_BOOTSTRAP_PASSWORD");
            if (!string.IsNullOrWhiteSpace(bootstrapPassword))
            {
                var bootstrapEmail = Environment.GetEnvironmentVariable("ADMIN_BOOTSTRAP_EMAIL")
                    ?? "admin@Miane.local";
                await SeedLocalAdminAsync(
                    userManager,
                    bootstrapEmail,
                    "System Admin",
                    "EMP0001",
                    "Admin",
                    bootstrapPassword,
                    new[] { "users.read", "users.write", "dashboard.view" });
                logger.LogWarning(
                    "Seeded bootstrap admin {Email} from ADMIN_BOOTSTRAP_PASSWORD. Rotate this password immediately.",
                    bootstrapEmail);
            }
            else
            {
                logger.LogInformation(
                    "Skipping admin seed outside Development (set ADMIN_BOOTSTRAP_PASSWORD to bootstrap once).");
            }
        }
    }

    private static async Task SeedLocalAdminAsync(
        UserManager<User> userManager,
        string email,
        string fullName,
        string employeeId,
        string role,
        string password,
        IEnumerable<string> permissions)
    {
        if (await userManager.FindByEmailAsync(email) is not null)
        {
            return;
        }

        var user = new User
        {
            UserName = email,
            Email = email,
            FullName = fullName,
            IsEmployee = true,
            EmployeeId = employeeId,
            EmailConfirmed = true,
            IsActive = true
        };

        var result = await userManager.CreateAsync(user, password);
        if (!result.Succeeded)
        {
            return;
        }

        await userManager.AddToRoleAsync(user, role);
        foreach (var permission in permissions)
        {
            await userManager.AddClaimAsync(user,
                new System.Security.Claims.Claim("Permission", permission));
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
