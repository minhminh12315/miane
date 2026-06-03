using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Trip.API.Domain.Entities;

namespace Trip.API.Data.Configurations;

public class TripConfiguration : IEntityTypeConfiguration<TripEntity>
{
    public void Configure(EntityTypeBuilder<TripEntity> builder)
    {
        builder.ToTable("Trips");
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(t => t.Description)
            .HasMaxLength(2000);

        builder.Property(t => t.InviteCode)
            .HasMaxLength(8)
            .IsRequired();

        builder.HasIndex(t => t.InviteCode)
            .IsUnique()
            .HasDatabaseName("IX_Trips_InviteCode");

        builder.HasIndex(t => t.CreatedByUserId)
            .HasDatabaseName("IX_Trips_CreatedByUserId");

        builder.Property(t => t.BaseCurrency)
            .HasMaxLength(3)
            .HasDefaultValue("VND")
            .IsRequired();

        builder.Property(t => t.Status)
            .HasConversion<int>();

        builder.HasMany(t => t.Members)
            .WithOne(m => m.Trip)
            .HasForeignKey(m => m.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Property(t => t.Version)
            .IsConcurrencyToken();
    }
}
