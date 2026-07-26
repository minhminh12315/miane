using BuildingBlocks.Caching;
using BuildingBlocks.Extensions;
using BuildingBlocks.Middleware;
using BuildingBlocks.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Trip.API.Data;
using Trip.API.Data.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Controllers & OpenAPI
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

// Database — PostgreSQL
builder.Services.AddDbContext<TripDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"), npgsqlOptions =>
        npgsqlOptions.EnableRetryOnFailure()));

// Redis
var redisConnectionString = builder.Configuration.GetValue<string>("Redis:ConnectionString") ?? "localhost:6370";
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = redisConnectionString;
});
builder.Services.AddSingleton<ICacheService, RedisCacheService>();

// BuildingBlocks: MediatR, FluentValidation, EventBus, Pipeline Behaviors
builder.Services.AddBuildingBlocks(typeof(Program).Assembly);
builder.Services.AddNotificationEventForwarding(builder.Configuration);
builder.Services.AddOutboxProcessor<TripDbContext>();

// Repositories
builder.Services.AddScoped<ITripRepository, TripRepository>();

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
            var db = scope.ServiceProvider.GetRequiredService<TripDbContext>();
            db.Database.Migrate();
            await TripDemoSeeder.SeedAsync(scope.ServiceProvider);
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
