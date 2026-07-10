using BuildingBlocks.Domain;
using Expense.API.Domain.Enums;

namespace Expense.API.Domain.Entities;

public class WalletMember : BaseEntity
{
    public Guid TripWalletId { get; set; }
    public Guid UserId { get; set; }
    public WalletMemberRole Role { get; set; } = WalletMemberRole.Member;
    public decimal? ExpectedContribution { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LeftAt { get; set; }
    public bool IsActive { get; set; } = true;

    public TripWallet TripWallet { get; set; } = null!;
}
