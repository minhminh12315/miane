using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using System.Threading.RateLimiting;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key is not configured");

var frontendOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "http://localhost:5173", "http://localhost:3000" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(frontendOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// Rate limiting: fixed window policy for all protected routes
var rateLimitPermit = builder.Configuration.GetValue<int>("RateLimiting:PermitLimit", 100);
var rateLimitWindow = builder.Configuration.GetValue<int>("RateLimiting:WindowSeconds", 60);

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("standard", limiterOptions =>
    {
        limiterOptions.PermitLimit = rateLimitPermit;
        limiterOptions.Window = TimeSpan.FromSeconds(rateLimitWindow);
        limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiterOptions.QueueLimit = 2;
    });
});

// YARP reverse proxy with transforms to propagate user claims as HTTP headers
builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .AddTransforms(transformBuilderContext =>
    {
        transformBuilderContext.AddRequestTransform(transformContext =>
        {
            var user = transformContext.HttpContext.User;
            if (user.Identity?.IsAuthenticated == true)
            {
                // Propagate UserId from JWT sub claim
                var userId = user.FindFirstValue("sub")
                    ?? user.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? string.Empty;

                // Propagate UserTier from custom claim
                var userTier = user.FindFirstValue("UserTier") ?? "0";

                transformContext.ProxyRequest.Headers.Remove("X-User-Id");
                transformContext.ProxyRequest.Headers.Remove("X-User-Tier");
                transformContext.ProxyRequest.Headers.Add("X-User-Id", userId);
                transformContext.ProxyRequest.Headers.Add("X-User-Tier", userTier);
            }

            return ValueTask.CompletedTask;
        });
    });

var app = builder.Build();

app.UseCors("AllowFrontend");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

// Enable YARP Middleware to start navigation
app.MapReverseProxy();

app.MapGet("/", () => "Miane Web Gateway");

app.Run();
