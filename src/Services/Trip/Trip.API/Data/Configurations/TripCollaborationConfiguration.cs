using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Trip.API.Domain.Entities;

namespace Trip.API.Data.Configurations;

public class TripCollaborationConfiguration :
    IEntityTypeConfiguration<TripRole>,
    IEntityTypeConfiguration<TripRolePermission>,
    IEntityTypeConfiguration<TripInvitation>,
    IEntityTypeConfiguration<TripShareLink>,
    IEntityTypeConfiguration<TripImage>,
    IEntityTypeConfiguration<TripPlan>,
    IEntityTypeConfiguration<TripActivity>,
    IEntityTypeConfiguration<TripBooking>,
    IEntityTypeConfiguration<TripFile>,
    IEntityTypeConfiguration<TripWeatherCache>,
    IEntityTypeConfiguration<TripLocation>,
    IEntityTypeConfiguration<TripJoinRequest>
{
    public void Configure(EntityTypeBuilder<TripRole> builder)
    {
        builder.ToTable("TripRoles");
        builder.HasKey(r => r.Id);

        builder.HasIndex(r => new { r.TripId, r.RoleName })
            .IsUnique()
            .HasDatabaseName("IX_TripRoles_TripId_RoleName");

        builder.Property(r => r.RoleName).HasMaxLength(80).IsRequired();
        builder.Property(r => r.Description).HasMaxLength(500);
        builder.Property(r => r.Permissions).HasColumnType("jsonb").HasDefaultValueSql("'[]'::jsonb").IsRequired();

        builder.HasMany(r => r.RolePermissions)
            .WithOne(p => p.Role)
            .HasForeignKey(p => p.TripRoleId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripRolePermission> builder)
    {
        builder.ToTable("TripRolePermissions");
        builder.HasKey(p => p.Id);

        builder.HasIndex(p => new { p.TripRoleId, p.PermissionKey })
            .IsUnique()
            .HasDatabaseName("IX_TripRolePermissions_RoleId_Key");

        builder.Property(p => p.PermissionKey).HasMaxLength(120).IsRequired();
        builder.Property(p => p.Description).HasMaxLength(500);
    }

    public void Configure(EntityTypeBuilder<TripInvitation> builder)
    {
        builder.ToTable("TripInvitations");
        builder.HasKey(i => i.Id);

        builder.HasIndex(i => i.Code)
            .IsUnique()
            .HasDatabaseName("IX_TripInvitations_Code");

        builder.HasIndex(i => new { i.TripId, i.Status })
            .HasDatabaseName("IX_TripInvitations_TripId_Status");

        builder.Property(i => i.Code).HasMaxLength(16).IsRequired();
        builder.Property(i => i.ShareUrl).HasMaxLength(1000).IsRequired();
        builder.Property(i => i.Method).HasConversion<int>();
        builder.Property(i => i.Status).HasConversion<int>();
    }

    public void Configure(EntityTypeBuilder<TripShareLink> builder)
    {
        builder.ToTable("TripShareLinks");
        builder.HasKey(s => s.Id);

        builder.HasIndex(s => s.Code)
            .IsUnique()
            .HasDatabaseName("IX_TripShareLinks_Code");

        builder.Property(s => s.Code).HasMaxLength(16).IsRequired();
        builder.Property(s => s.Url).HasMaxLength(1000).IsRequired();
        builder.Property(s => s.Type).HasConversion<int>();
    }

    public void Configure(EntityTypeBuilder<TripImage> builder)
    {
        builder.ToTable("TripImages");
        builder.HasKey(i => i.Id);

        builder.HasIndex(i => new { i.TripId, i.IsCover })
            .HasDatabaseName("IX_TripImages_TripId_IsCover");

        builder.HasIndex(i => i.CacheKey)
            .HasDatabaseName("IX_TripImages_CacheKey");

        builder.Property(i => i.ImageUrl).HasMaxLength(1000).IsRequired();
        builder.Property(i => i.Destination).HasMaxLength(240);
        builder.Property(i => i.Prompt).HasMaxLength(1000);
        builder.Property(i => i.CacheKey).HasMaxLength(128);
    }

    public void Configure(EntityTypeBuilder<TripPlan> builder)
    {
        builder.ToTable("TripPlans");
        builder.HasKey(p => p.Id);

        builder.HasIndex(p => new { p.TripId, p.PlanDate })
            .HasDatabaseName("IX_TripPlans_TripId_PlanDate");

        builder.Property(p => p.Title).HasMaxLength(180).IsRequired();
        builder.Property(p => p.Notes).HasMaxLength(2000);

        builder.HasOne(p => p.Trip)
            .WithMany()
            .HasForeignKey(p => p.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(p => p.Activities)
            .WithOne(a => a.Plan)
            .HasForeignKey(a => a.TripPlanId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripActivity> builder)
    {
        builder.ToTable("TripActivities");
        builder.HasKey(a => a.Id);

        builder.HasIndex(a => new { a.TripId, a.TripPlanId, a.SortOrder })
            .HasDatabaseName("IX_TripActivities_Trip_Plan_Order");

        builder.Property(a => a.Title).HasMaxLength(200).IsRequired();
        builder.Property(a => a.Slot).HasMaxLength(40).IsRequired();
        builder.Property(a => a.Category).HasMaxLength(80).IsRequired();
        builder.Property(a => a.LocationName).HasMaxLength(240);
        builder.Property(a => a.Notes).HasMaxLength(2000);
        builder.Property(a => a.ColorHex).HasMaxLength(16);
        builder.Property(a => a.Latitude).HasPrecision(9, 6);
        builder.Property(a => a.Longitude).HasPrecision(9, 6);

        builder.HasOne(a => a.Trip)
            .WithMany()
            .HasForeignKey(a => a.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripBooking> builder)
    {
        builder.ToTable("TripBookings");
        builder.HasKey(b => b.Id);

        builder.HasIndex(b => new { b.TripId, b.Type, b.StartsAt })
            .HasDatabaseName("IX_TripBookings_TripId_Type_StartsAt");

        builder.Property(b => b.Type).HasMaxLength(60).IsRequired();
        builder.Property(b => b.Title).HasMaxLength(220).IsRequired();
        builder.Property(b => b.ConfirmationNumber).HasMaxLength(120);
        builder.Property(b => b.LocationName).HasMaxLength(240);
        builder.Property(b => b.Status).HasMaxLength(60).IsRequired();
        builder.Property(b => b.AttachmentUrl).HasMaxLength(1000);
        builder.Property(b => b.Notes).HasMaxLength(2000);

        builder.HasOne(b => b.Trip)
            .WithMany()
            .HasForeignKey(b => b.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripFile> builder)
    {
        builder.ToTable("TripFiles");
        builder.HasKey(f => f.Id);

        builder.HasIndex(f => new { f.TripId, f.Folder })
            .HasDatabaseName("IX_TripFiles_TripId_Folder");

        builder.Property(f => f.Folder).HasMaxLength(160).IsRequired();
        builder.Property(f => f.FileName).HasMaxLength(260).IsRequired();
        builder.Property(f => f.FileUrl).HasMaxLength(1000).IsRequired();
        builder.Property(f => f.ContentType).HasMaxLength(120);
        builder.Property(f => f.Permissions).HasColumnType("jsonb").HasDefaultValueSql("'[]'::jsonb").IsRequired();
        builder.Property(f => f.Tags).HasColumnType("jsonb").HasDefaultValueSql("'[]'::jsonb").IsRequired();

        builder.HasOne(f => f.Trip)
            .WithMany()
            .HasForeignKey(f => f.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripWeatherCache> builder)
    {
        builder.ToTable("TripWeatherCache");
        builder.HasKey(w => w.Id);

        builder.HasIndex(w => new { w.TripId, w.ForecastDate })
            .IsUnique()
            .HasDatabaseName("IX_TripWeatherCache_TripId_ForecastDate");

        builder.Property(w => w.Destination).HasMaxLength(240).IsRequired();
        builder.Property(w => w.PayloadJson).HasColumnType("jsonb").HasDefaultValueSql("'{}'::jsonb").IsRequired();

        builder.HasOne(w => w.Trip)
            .WithMany()
            .HasForeignKey(w => w.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripLocation> builder)
    {
        builder.ToTable("TripLocations");
        builder.HasKey(l => l.Id);

        builder.HasIndex(l => new { l.TripId, l.Type })
            .HasDatabaseName("IX_TripLocations_TripId_Type");

        builder.Property(l => l.Name).HasMaxLength(220).IsRequired();
        builder.Property(l => l.Type).HasMaxLength(80).IsRequired();
        builder.Property(l => l.Address).HasMaxLength(500);
        builder.Property(l => l.Notes).HasMaxLength(2000);
        builder.Property(l => l.Latitude).HasPrecision(9, 6);
        builder.Property(l => l.Longitude).HasPrecision(9, 6);

        builder.HasOne(l => l.Trip)
            .WithMany()
            .HasForeignKey(l => l.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<TripJoinRequest> builder)
    {
        builder.ToTable("TripJoinRequests");
        builder.HasKey(r => r.Id);

        builder.HasIndex(r => new { r.TripId, r.UserId, r.Status })
            .HasDatabaseName("IX_TripJoinRequests_TripId_UserId_Status");

        builder.Property(r => r.NickName).HasMaxLength(100);
        builder.Property(r => r.Message).HasMaxLength(1000);
        builder.Property(r => r.Status).HasConversion<int>();

        builder.HasOne(r => r.Trip)
            .WithMany()
            .HasForeignKey(r => r.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
