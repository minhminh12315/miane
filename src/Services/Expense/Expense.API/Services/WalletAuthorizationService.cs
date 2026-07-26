using BuildingBlocks.Exceptions;
using Expense.API.Data;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Services;

/// <summary>
/// Shared authorization helpers for wallet custodian / trip-scoped money ops.
/// </summary>
public sealed class WalletAuthorizationService
{
    private readonly ExpenseDbContext _dbContext;
    private readonly ITripMembershipClient _tripMembership;

    public WalletAuthorizationService(
        ExpenseDbContext dbContext,
        ITripMembershipClient tripMembership)
    {
        _dbContext = dbContext;
        _tripMembership = tripMembership;
    }

    public Task EnsureTripMemberAsync(Guid tripId, CancellationToken cancellationToken = default) =>
        _tripMembership.EnsureMemberAsync(tripId, cancellationToken);

    public async Task EnsureWalletTripMemberAsync(Guid walletId, CancellationToken cancellationToken = default)
    {
        var tripId = await _dbContext.TripWallets
            .AsNoTracking()
            .Where(w => w.Id == walletId)
            .Select(w => (Guid?)w.TripId)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("ví chung", walletId);

        await _tripMembership.EnsureMemberAsync(tripId, cancellationToken);
    }

    public async Task EnsureCurrentCustodianAsync(
        Guid walletId,
        Guid callerUserId,
        CancellationToken cancellationToken = default)
    {
        var wallet = await _dbContext.TripWallets
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.Id == walletId, cancellationToken)
            ?? throw new NotFoundException("ví chung", walletId);

        await _tripMembership.EnsureMemberAsync(wallet.TripId, cancellationToken);

        if (wallet.CurrentCustodianUserId != callerUserId)
        {
            throw new ForbiddenAccessException("Chỉ người giữ ví hiện tại mới được thực hiện thao tác này.");
        }
    }
}
