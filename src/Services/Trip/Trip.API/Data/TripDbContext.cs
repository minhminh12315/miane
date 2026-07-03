using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Trip.API.Domain.Entities;

namespace Trip.API.Data;

public class TripDbContext : BaseDbContext
{
    public DbSet<TripEntity> Trips => Set<TripEntity>();
    public DbSet<TripMember> TripMembers => Set<TripMember>();
    public DbSet<TripRole> TripRoles => Set<TripRole>();
    public DbSet<TripRolePermission> TripRolePermissions => Set<TripRolePermission>();
    public DbSet<TripInvitation> TripInvitations => Set<TripInvitation>();
    public DbSet<TripImage> TripImages => Set<TripImage>();
    public DbSet<TripPlan> TripPlans => Set<TripPlan>();
    public DbSet<TripActivity> TripActivities => Set<TripActivity>();
    public DbSet<TripBooking> TripBookings => Set<TripBooking>();
    public DbSet<TripFile> TripFiles => Set<TripFile>();
    public DbSet<TripWeatherCache> TripWeatherCache => Set<TripWeatherCache>();
    public DbSet<TripLocation> TripLocations => Set<TripLocation>();
    public DbSet<TripShareLink> TripShareLinks => Set<TripShareLink>();
    public DbSet<TripJoinRequest> TripJoinRequests => Set<TripJoinRequest>();

    public TripDbContext(DbContextOptions<TripDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(TripDbContext).Assembly);
    }
}
