using BuildingBlocks.Extensions;
using BuildingBlocks.Middleware;
using BuildingBlocks.Notifications;
using Microsoft.EntityFrameworkCore;
using Notification.API.Data;
using Notification.API.EventHandlers;

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
builder.Services.AddDbContext<NotificationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"), npgsqlOptions =>
        npgsqlOptions.EnableRetryOnFailure()));

// BuildingBlocks
builder.Services.AddBuildingBlocks(typeof(Program).Assembly);

// Firebase
builder.Services.AddFirebaseNotifications(builder.Configuration);

// Event processing
builder.Services.AddScoped<NotificationEventProcessor>();

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
            var db = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();
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
