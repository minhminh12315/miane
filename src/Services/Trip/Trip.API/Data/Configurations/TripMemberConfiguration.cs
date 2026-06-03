using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Trip.API.Domain.Entities;

namespace Trip.API.Data.Configurations;

public class TripMemberConfiguration : IEntityTypeConfiguration<TripMember>
{
    public void Configure(EntityTypeBuilder<TripMember> builder)
    {
        builder.ToTable("TripMembers");
        builder.HasKey(m => m.Id);

        builder.HasIndex(m => new { m.TripId, m.UserId })
            .IsUnique()
            .HasDatabaseName("IX_TripMembers_TripId_UserId");

        builder.Property(m => m.NickName)
            .HasMaxLength(100);

        builder.Property(m => m.Role)
            .HasConversion<int>();
    }
}
