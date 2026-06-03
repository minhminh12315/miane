using BuildingBlocks.AI;
using BuildingBlocks.Caching;
using BuildingBlocks.Extensions;
using BuildingBlocks.Middleware;
using Expense.API.Data;
using Expense.API.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

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

// BuildingBlocks
builder.Services.AddBuildingBlocks(typeof(Program).Assembly);
builder.Services.AddOutboxProcessor<ExpenseDbContext>();

// AI Services
builder.Services.AddAiServices(builder.Configuration);

// Domain Services
builder.Services.AddSingleton<IExchangeRateProvider, StaticExchangeRateProvider>();
builder.Services.AddScoped<CurrencyConversionService>();
builder.Services.AddScoped<DebtSimplificationService>();

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

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseCors("AllowFrontend");
app.MapControllers();

app.Run();
