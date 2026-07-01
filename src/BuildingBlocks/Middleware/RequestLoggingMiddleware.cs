using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace BuildingBlocks.Middleware;

/// <summary>
/// Middleware to log details of incoming HTTP requests and responses.
/// </summary>
public sealed class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var request = context.Request;
        
        _logger.LogInformation("[MIANE Request] Start: {Method} {Path}{QueryString}", 
            request.Method, request.Path, request.QueryString);

        try
        {
            await _next(context);
            stopwatch.Stop();
            
            _logger.LogInformation("[MIANE Response] End: {Method} {Path} -> {StatusCode} ({ElapsedMs} ms)", 
                request.Method, request.Path, context.Response.StatusCode, stopwatch.ElapsedMilliseconds);
        }
        catch (Exception)
        {
            stopwatch.Stop();
            _logger.LogError("[MIANE Response] Error: {Method} {Path} failed in {ElapsedMs} ms", 
                request.Method, request.Path, stopwatch.ElapsedMilliseconds);
            throw;
        }
    }
}
