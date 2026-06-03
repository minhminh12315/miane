namespace BuildingBlocks.Domain;

/// <summary>
/// Marker base class for aggregate roots. Only aggregate roots should be
/// persisted directly and should own domain event publishing.
/// </summary>
public abstract class AggregateRoot : BaseEntity
{
    /// <summary>
    /// Incremented on every successful persistence to support optimistic concurrency.
    /// </summary>
    public int Version { get; set; }
}
