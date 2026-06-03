using BuildingBlocks.Domain;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using BuildingBlocks.EventBus;

namespace BuildingBlocks.Data;

/// <summary>
/// Abstract base DbContext that provides:
/// 1. Automatic CreatedAt/UpdatedAt timestamp management
/// 2. Domain event collection and outbox persistence
/// 3. Outbox table configuration
/// </summary>
public abstract class BaseDbContext : DbContext
{
    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();

    protected BaseDbContext(DbContextOptions options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<OutboxMessage>(entity =>
        {
            entity.ToTable("OutboxMessages");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Type).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Content).IsRequired();
            entity.HasIndex(e => e.ProcessedOn)
                  .HasFilter("\"ProcessedOn\" IS NULL")
                  .HasDatabaseName("IX_OutboxMessages_Unprocessed");
        });
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        SetTimestamps();
        await PersistDomainEventsToOutboxAsync();
        return await base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        SetTimestamps();
        PersistDomainEventsToOutboxAsync().GetAwaiter().GetResult();
        return base.SaveChanges();
    }

    private void SetTimestamps()
    {
        var entries = ChangeTracker.Entries<BaseEntity>();
        var now = DateTime.UtcNow;

        foreach (var entry in entries)
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = now;
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = now;
                    break;
            }
        }
    }

    private Task PersistDomainEventsToOutboxAsync()
    {
        var aggregatesWithEvents = ChangeTracker.Entries<BaseEntity>()
            .Where(e => e.Entity.DomainEvents.Count > 0)
            .Select(e => e.Entity)
            .ToList();

        var outboxMessages = new List<OutboxMessage>();

        foreach (var aggregate in aggregatesWithEvents)
        {
            foreach (var domainEvent in aggregate.DomainEvents)
            {
                var outboxMessage = new OutboxMessage
                {
                    Type = domainEvent.GetType().AssemblyQualifiedName ?? domainEvent.GetType().FullName!,
                    Content = JsonSerializer.Serialize(domainEvent, domainEvent.GetType()),
                    OccurredOn = domainEvent.OccurredOn
                };
                outboxMessages.Add(outboxMessage);
            }

            aggregate.ClearDomainEvents();
        }

        if (outboxMessages.Count > 0)
        {
            OutboxMessages.AddRange(outboxMessages);
        }

        return Task.CompletedTask;
    }
}
