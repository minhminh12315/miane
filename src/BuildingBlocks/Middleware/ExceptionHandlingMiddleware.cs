using BuildingBlocks.Exceptions;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Text.Json;

namespace BuildingBlocks.Middleware;

/// <summary>
/// Global exception handling middleware that maps domain exceptions to proper
/// HTTP status codes and returns consistent JSON error responses.
/// </summary>
public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false
    };

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, errorCode, message, errors) = exception switch
        {
            ValidationException validationEx => (
                HttpStatusCode.BadRequest,
                "VALIDATION_ERROR",
                "One or more validation errors occurred.",
                validationEx.Errors.Select(e => new { field = e.PropertyName, error = e.ErrorMessage }).ToArray() as object
            ),
            TierLimitExceededException tierEx => (
                HttpStatusCode.UnprocessableEntity,
                tierEx.ErrorCode,
                tierEx.Message,
                (object?)null
            ),
            NotFoundException notFoundEx => (
                HttpStatusCode.NotFound,
                notFoundEx.ErrorCode,
                notFoundEx.Message,
                (object?)null
            ),
            ForbiddenAccessException forbiddenEx => (
                HttpStatusCode.Forbidden,
                forbiddenEx.ErrorCode,
                forbiddenEx.Message,
                (object?)null
            ),
            ConflictException conflictEx => (
                HttpStatusCode.Conflict,
                conflictEx.ErrorCode,
                conflictEx.Message,
                (object?)null
            ),
            DomainException domainEx => (
                HttpStatusCode.BadRequest,
                domainEx.ErrorCode,
                domainEx.Message,
                (object?)null
            ),
            UnauthorizedAccessException => (
                HttpStatusCode.Unauthorized,
                "UNAUTHORIZED",
                "Authentication required.",
                (object?)null
            ),
            _ => (
                HttpStatusCode.InternalServerError,
                "INTERNAL_ERROR",
                "An unexpected error occurred.",
                (object?)null
            )
        };

        if (statusCode == HttpStatusCode.InternalServerError)
        {
            _logger.LogError(exception, "[MIANE] Unhandled exception");
        }
        else
        {
            _logger.LogWarning(exception, "[MIANE] Handled exception: {ErrorCode}", errorCode);
        }

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var response = new
        {
            errorCode,
            message,
            errors,
            timestamp = DateTime.UtcNow
        };

        await context.Response.WriteAsync(JsonSerializer.Serialize(response, JsonOptions));
    }
}
