using BuildingBlocks.AI;
using BuildingBlocks.Caching;
using BuildingBlocks.Extensions;
using BuildingBlocks.Middleware;
using BuildingBlocks.Security;
using Expense.API.Data;
using Expense.API.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Options;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

// JWT required — TrustedUserHeadersMiddleware re-derives X-User-* from claims only.
var jwtKey = JwtSigningKeyGuard.RequireConfiguredKey(
    builder.Configuration["Jwt:Key"], builder.Environment);
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

// CORS
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

// Database
builder.Services.AddDbContext<ExpenseDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"), npgsqlOptions =>
        npgsqlOptions.EnableRetryOnFailure()));

// Redis
var redisConnectionString = builder.Configuration.GetValue<string>("Redis:ConnectionString") ?? "localhost:6370";
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = redisConnectionString;
});
builder.Services.AddSingleton<ICacheService, RedisCacheService>();

// VietQR
builder.Services.Configure<VietQrOptions>(builder.Configuration.GetSection("VietQr"));
builder.Services.AddDataProtection();
builder.Services.AddSingleton<PaymentAccountProtector>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient<ITripMembershipClient, TripMembershipClient>((sp, client) =>
{
    var baseUrl = sp.GetRequiredService<IConfiguration>()["Services:Trip:BaseUrl"]
        ?? "http://localhost:5128/";
    client.BaseAddress = new Uri(baseUrl.EndsWith('/') ? baseUrl : $"{baseUrl}/");
    client.Timeout = TimeSpan.FromSeconds(10);
});
builder.Services.AddHttpClient<IVietQrClient, VietQrClient>((serviceProvider, client) =>
{
    var options = serviceProvider.GetRequiredService<IOptions<VietQrOptions>>().Value;
    var baseUrl = string.IsNullOrWhiteSpace(options.BaseUrl)
        ? "https://api.vietqr.io/"
        : options.BaseUrl;
    client.BaseAddress = new Uri(baseUrl.EndsWith('/') ? baseUrl : $"{baseUrl}/");
    client.Timeout = TimeSpan.FromSeconds(15);
});

// BuildingBlocks
builder.Services.AddBuildingBlocks(typeof(Program).Assembly);
builder.Services.AddNotificationEventForwarding(builder.Configuration);
builder.Services.AddOutboxProcessor<ExpenseDbContext>();

// AI Services
builder.Services.AddAiServices(builder.Configuration);

// Domain Services
builder.Services.AddSingleton<IExchangeRateProvider>(sp =>
{
    var env = sp.GetRequiredService<IHostEnvironment>();
    var config = sp.GetRequiredService<IConfiguration>();
    var allowStatic = config.GetValue("ExchangeRates:AllowStatic", false);

    if (!env.IsDevelopment() && !allowStatic)
    {
        throw new InvalidOperationException(
            "StaticExchangeRateProvider is not allowed outside Development. " +
            "Configure a live FX provider, or set ExchangeRates:AllowStatic=true explicitly.");
    }

    if (!env.IsDevelopment())
    {
        var logger = sp.GetRequiredService<ILoggerFactory>().CreateLogger("ExchangeRateProvider");
        logger.LogWarning(
            "Using StaticExchangeRateProvider outside Development (ExchangeRates:AllowStatic=true).");
    }

    return new StaticExchangeRateProvider();
});
builder.Services.AddScoped<CurrencyConversionService>();
builder.Services.AddScoped<DebtSimplificationService>();
builder.Services.AddScoped<WalletLedgerService>();
builder.Services.AddScoped<WalletAuthorizationService>();
builder.Services.AddScoped<SplitCalculationService>();
builder.Services.AddScoped<DebtOptimizationServiceV2>();

var app = builder.Build();

// Auto-migrate in Development only
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var retries = 6;
    for (var attempt = 1; attempt <= retries; attempt++)
    {
        try
        {
            var db = scope.ServiceProvider.GetRequiredService<ExpenseDbContext>();
            db.Database.Migrate();
            await ExpenseDemoSeeder.SeedAsync(scope.ServiceProvider);
            break;
        }
        catch (Exception) when (attempt < retries)
        {
            await Task.Delay(TimeSpan.FromSeconds(5));
        }
    }
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseCors("AllowFrontend");
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<TrustedUserHeadersMiddleware>();
app.MapControllers();

app.Run();
