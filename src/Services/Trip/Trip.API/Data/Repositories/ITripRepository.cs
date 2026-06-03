using BuildingBlocks.Data;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;

namespace Trip.API.Data.Repositories;

public interface ITripRepository : IRepository<TripEntity>
{
    Task<TripEntity?> GetByInviteCodeAsync(string inviteCode, CancellationToken cancellationToken = default);
    Task<TripEntity?> GetWithMembersAsync(Guid tripId, CancellationToken cancellationToken = default);
    Task<int> GetActiveTripCountByUserAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<int> GetMemberCountByTripAsync(Guid tripId, CancellationToken cancellationToken = default);
    Task<List<TripEntity>> GetTripsByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> IsUserMemberOfTripAsync(Guid tripId, Guid userId, CancellationToken cancellationToken = default);
    Task<TripMember?> GetTripMemberAsync(Guid tripId, Guid userId, CancellationToken cancellationToken = default);
    Task AddMemberAsync(TripMember member, CancellationToken cancellationToken = default);
}
