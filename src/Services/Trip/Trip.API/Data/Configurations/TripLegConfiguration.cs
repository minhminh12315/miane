using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Trip.API.Domain.Entities;

namespace Trip.API.Data.Configurations;

public class TripLegConfiguration : IEntityTypeConfiguration<TripLeg>
{
    public void Configure(EntityTypeBuilder<TripLeg> builder)
    {
        builder.ToTable("TripLegs");
        builder.HasKey(l => l.Id);

        builder.HasIndex(l => new { l.TripId, l.Order })
            .HasDatabaseName("IX_TripLegs_TripId_Order");

        builder.Property(l => l.Name).HasMaxLength(220).IsRequired();
        builder.Property(l => l.DestinationCity).HasMaxLength(160);
        builder.Property(l => l.DestinationCountry).HasMaxLength(160);
        builder.Property(l => l.Notes).HasMaxLength(2000);
        builder.Property(l => l.Latitude).HasPrecision(9, 6);
        builder.Property(l => l.Longitude).HasPrecision(9, 6);

        builder.HasOne(l => l.Trip)
            .WithMany()
            .HasForeignKey(l => l.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
