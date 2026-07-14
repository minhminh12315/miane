using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;

namespace Trip.API.Data.Repositories;

public class TripRepository : BaseRepository<TripEntity, TripDbContext>, ITripRepository
{
    public TripRepository(TripDbContext dbContext) : base(dbContext)
    {
    }

    public async Task<TripEntity?> GetByInviteCodeAsync(string inviteCode, CancellationToken cancellationToken = default)
    {
        return await DbSet
            .Include(t => t.Members)
                .ThenInclude(m => m.CustomRole)
            .Include(t => t.ShareLinks)
            .FirstOrDefaultAsync(t => t.InviteCode == inviteCode, cancellationToken);
    }

    public async Task<TripEntity?> GetWithMembersAsync(Guid tripId, CancellationToken cancellationToken = default)
    {
        return await DbSet
            .Include(t => t.Members)
                .ThenInclude(m => m.CustomRole)
            .Include(t => t.Roles)
                .ThenInclude(r => r.RolePermissions)
            .Include(t => t.ShareLinks)
            .Include(t => t.Images)
            .FirstOrDefaultAsync(t => t.Id == tripId, cancellationToken);
    }

    public async Task<int> GetActiveTripCountByUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var today = DateTime.UtcNow.Date;
        return await DbContext.TripMembers
            .Where(m => m.UserId == userId)
            .Join(DbSet, m => m.TripId, t => t.Id, (m, t) => t)
            .Where(t => t.Status == TripStatus.Active &&
                (!t.EndDate.HasValue || t.EndDate.Value >= today))
            .CountAsync(cancellationToken);
    }

    public async Task<int> GetMemberCountByTripAsync(Guid tripId, CancellationToken cancellationToken = default)
    {
        return await DbContext.TripMembers
            .CountAsync(m => m.TripId == tripId, cancellationToken);
    }

    public async Task<List<TripEntity>> GetTripsByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await DbContext.TripMembers
            .Where(m => m.UserId == userId)
            .Join(
                DbSet
                    .Include(t => t.Members)
                        .ThenInclude(m => m.CustomRole)
                    .Include(t => t.ShareLinks)
                    .Include(t => t.Images),
                m => m.TripId,
                t => t.Id,
                (m, t) => t)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> IsUserMemberOfTripAsync(Guid tripId, Guid userId, CancellationToken cancellationToken = default)
    {
        return await DbContext.TripMembers
            .AnyAsync(m => m.TripId == tripId && m.UserId == userId, cancellationToken);
    }

    public async Task<TripMember?> GetTripMemberAsync(Guid tripId, Guid userId, CancellationToken cancellationToken = default)
    {
        return await DbContext.TripMembers
            .FirstOrDefaultAsync(m => m.TripId == tripId && m.UserId == userId, cancellationToken);
    }

    public async Task AddMemberAsync(TripMember member, CancellationToken cancellationToken = default)
    {
        await DbContext.TripMembers.AddAsync(member, cancellationToken);
    }
}
