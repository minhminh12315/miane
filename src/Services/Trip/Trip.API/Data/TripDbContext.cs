using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Trip.API.Domain.Entities;

namespace Trip.API.Data;

public class TripDbContext : BaseDbContext
{
    public DbSet<TripEntity> Trips => Set<TripEntity>();
    public DbSet<TripMember> TripMembers => Set<TripMember>();

    public TripDbContext(DbContextOptions<TripDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(TripDbContext).Assembly);
    }
}
