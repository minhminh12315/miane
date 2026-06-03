using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Notification.API.Domain.Entities;

namespace Notification.API.Data;

public class NotificationDbContext : BaseDbContext
{
    public DbSet<DeviceRegistration> DeviceRegistrations => Set<DeviceRegistration>();
    public DbSet<NotificationLog> NotificationLogs => Set<NotificationLog>();

    public NotificationDbContext(DbContextOptions<NotificationDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<DeviceRegistration>(entity =>
        {
            entity.ToTable("DeviceRegistrations");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.FcmToken).HasMaxLength(500).IsRequired();
            entity.Property(e => e.DevicePlatform).HasMaxLength(20).IsRequired();
            entity.HasIndex(e => e.UserId).HasDatabaseName("IX_DeviceRegistrations_UserId");
            entity.HasIndex(e => e.FcmToken).IsUnique().HasDatabaseName("IX_DeviceRegistrations_FcmToken");
        });

        modelBuilder.Entity<NotificationLog>(entity =>
        {
            entity.ToTable("NotificationLogs");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Body).HasMaxLength(1000).IsRequired();
            entity.Property(e => e.EventType).HasMaxLength(100).IsRequired();
            entity.HasIndex(e => new { e.UserId, e.IsRead }).HasDatabaseName("IX_NotificationLogs_UserId_IsRead");
        });
    }
}
