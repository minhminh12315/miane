using System.Diagnostics;
using MediatR;
using Microsoft.Extensions.Logging;

namespace BuildingBlocks.Behaviors;

/// <summary>
/// MediatR pipeline behavior that logs every request with structured metadata
/// including the request type, duration, and whether it succeeded or faulted.
/// </summary>
public sealed class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var requestId = Guid.NewGuid();

        _logger.LogInformation(
            "[MIANE] Handling {RequestName} (CorrelationId: {CorrelationId})",
            requestName, requestId);

        var stopwatch = Stopwatch.StartNew();

        try
        {
            var response = await next();
            stopwatch.Stop();

            _logger.LogInformation(
                "[MIANE] Handled {RequestName} in {ElapsedMs}ms (CorrelationId: {CorrelationId})",
                requestName, stopwatch.ElapsedMilliseconds, requestId);

            return response;
        }
        catch (Exception ex)
        {
            stopwatch.Stop();

            _logger.LogError(ex,
                "[MIANE] {RequestName} FAULTED after {ElapsedMs}ms (CorrelationId: {CorrelationId})",
                requestName, stopwatch.ElapsedMilliseconds, requestId);

            throw;
        }
    }
}
