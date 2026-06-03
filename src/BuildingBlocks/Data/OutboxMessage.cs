namespace BuildingBlocks.Data;

/// <summary>
/// Outbox message entity for the transactional outbox pattern.
/// Events are persisted in the same transaction as domain state changes,
/// then published asynchronously by the <see cref="OutboxProcessor"/>.
/// </summary>
public class OutboxMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// Fully-qualified CLR type name of the integration event.
    /// </summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// JSON-serialized integration event payload.
    /// </summary>
    public string Content { get; set; } = string.Empty;

    public DateTime OccurredOn { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Null until the outbox processor successfully publishes the event.
    /// </summary>
    public DateTime? ProcessedOn { get; set; }

    /// <summary>
    /// Error details if publishing failed.
    /// </summary>
    public string? Error { get; set; }

    public int RetryCount { get; set; }
}
