using BuildingBlocks.Data;
using Expense.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Expense.API.Data;

public class ExpenseDbContext : BaseDbContext
{
    public DbSet<ExpenseEntity> Expenses => Set<ExpenseEntity>();
    public DbSet<ExpenseSplit> ExpenseSplits => Set<ExpenseSplit>();
    public DbSet<TripPool> TripPools => Set<TripPool>();
    public DbSet<PoolContribution> PoolContributions => Set<PoolContribution>();
    public DbSet<DebtRecord> DebtRecords => Set<DebtRecord>();
    public DbSet<TripWallet> TripWallets => Set<TripWallet>();
    public DbSet<WalletMember> WalletMembers => Set<WalletMember>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<WalletBalance> WalletBalances => Set<WalletBalance>();
    public DbSet<FundRequest> FundRequests => Set<FundRequest>();
    public DbSet<FundContribution> FundContributions => Set<FundContribution>();
    public DbSet<ExpenseItem> ExpenseItems => Set<ExpenseItem>();
    public DbSet<ExpenseParticipant> ExpenseParticipants => Set<ExpenseParticipant>();
    public DbSet<ExpensePaymentSource> ExpensePaymentSources => Set<ExpensePaymentSource>();
    public DbSet<Debt> Debts => Set<Debt>();
    public DbSet<Settlement> Settlements => Set<Settlement>();
    public DbSet<PaymentMethod> PaymentMethods => Set<PaymentMethod>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<QRPayment> QRPayments => Set<QRPayment>();
    public DbSet<PaymentWebhookEvent> PaymentWebhookEvents => Set<PaymentWebhookEvent>();
    public DbSet<TransactionHistory> TransactionHistories => Set<TransactionHistory>();

    public ExpenseDbContext(DbContextOptions<ExpenseDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ExpenseEntity>(entity =>
        {
            entity.ToTable("Expenses");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(300);
            entity.Property(e => e.Description).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(60);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.ConvertedAmount).HasPrecision(18, 4);
            entity.Property(e => e.ExchangeRate).HasPrecision(18, 8);
            entity.Property(e => e.RoundingDelta).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.SplitType).HasConversion<int>();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.HasIndex(e => e.TripId).HasDatabaseName("IX_Expenses_TripId");
            entity.HasMany(e => e.Splits).WithOne(s => s.Expense).HasForeignKey(s => s.ExpenseId).OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(e => e.Items).WithOne(i => i.Expense).HasForeignKey(i => i.ExpenseId).OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(e => e.Participants).WithOne(p => p.Expense).HasForeignKey(p => p.ExpenseId).OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(e => e.PaymentSources).WithOne(p => p.Expense).HasForeignKey(p => p.ExpenseId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ExpenseSplit>(entity =>
        {
            entity.ToTable("ExpenseSplits");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.HasIndex(e => new { e.ExpenseId, e.UserId }).HasDatabaseName("IX_ExpenseSplits_ExpenseId_UserId");
        });

        modelBuilder.Entity<TripPool>(entity =>
        {
            entity.ToTable("TripPools");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Balance).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.HasIndex(e => e.TripId).IsUnique().HasDatabaseName("IX_TripPools_TripId");
            entity.HasMany(e => e.Contributions).WithOne(c => c.TripPool).HasForeignKey(c => c.TripPoolId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PoolContribution>(entity =>
        {
            entity.ToTable("PoolContributions");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
        });

        modelBuilder.Entity<DebtRecord>(entity =>
        {
            entity.ToTable("DebtRecords");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.HasIndex(e => new { e.TripId, e.IsSettled }).HasDatabaseName("IX_DebtRecords_TripId_IsSettled");
        });

        modelBuilder.Entity<TripWallet>(entity =>
        {
            entity.ToTable("TripWallets");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(120).IsRequired();
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.OpeningBalance).HasPrecision(18, 4);
            entity.Property(e => e.CurrentBalance).HasPrecision(18, 4);
            entity.Property(e => e.TotalContributed).HasPrecision(18, 4);
            entity.Property(e => e.TotalSpent).HasPrecision(18, 4);
            entity.Property(e => e.Status).HasConversion<int>();
            entity.HasIndex(e => e.TripId).IsUnique().HasDatabaseName("IX_TripWallets_TripId");
            entity.HasMany(e => e.Members).WithOne(m => m.TripWallet).HasForeignKey(m => m.TripWalletId).OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(e => e.Transactions).WithOne(t => t.TripWallet).HasForeignKey(t => t.TripWalletId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<WalletMember>(entity =>
        {
            entity.ToTable("WalletMembers");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Role).HasConversion<int>();
            entity.Property(e => e.ExpectedContribution).HasPrecision(18, 4);
            entity.HasIndex(e => new { e.TripWalletId, e.UserId }).IsUnique().HasDatabaseName("IX_WalletMembers_TripWalletId_UserId");
        });

        modelBuilder.Entity<WalletTransaction>(entity =>
        {
            entity.ToTable("WalletTransactions");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TransactionNo).HasMaxLength(40).IsRequired();
            entity.Property(e => e.Type).HasConversion<int>();
            entity.Property(e => e.Direction).HasConversion<int>();
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.BalanceAfter).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.Property(e => e.MetadataJson).HasColumnType("jsonb");
            entity.HasIndex(e => e.TransactionNo).IsUnique().HasDatabaseName("IX_WalletTransactions_TransactionNo");
            entity.HasIndex(e => new { e.TripWalletId, e.OccurredAt }).HasDatabaseName("IX_WalletTransactions_TripWalletId_OccurredAt");
            entity.HasIndex(e => e.PaymentId).HasDatabaseName("IX_WalletTransactions_PaymentId");
        });

        modelBuilder.Entity<WalletBalance>(entity =>
        {
            entity.ToTable("WalletBalances");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ContributedAmount).HasPrecision(18, 4);
            entity.Property(e => e.ExpectedAmount).HasPrecision(18, 4);
            entity.Property(e => e.PendingAmount).HasPrecision(18, 4);
            entity.Property(e => e.RefundableAmount).HasPrecision(18, 4);
            entity.HasIndex(e => new { e.TripWalletId, e.UserId }).IsUnique().HasDatabaseName("IX_WalletBalances_TripWalletId_UserId");
            entity.HasOne(e => e.TripWallet).WithMany().HasForeignKey(e => e.TripWalletId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<FundRequest>(entity =>
        {
            entity.ToTable("FundRequests");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.TargetAmount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.AllocationType).HasConversion<int>();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.Property(e => e.Note).HasMaxLength(500);
            entity.HasIndex(e => new { e.TripWalletId, e.Status }).HasDatabaseName("IX_FundRequests_TripWalletId_Status");
            entity.HasOne(e => e.TripWallet).WithMany().HasForeignKey(e => e.TripWalletId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<FundContribution>(entity =>
        {
            entity.ToTable("FundContributions");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ExpectedAmount).HasPrecision(18, 4);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.HasIndex(e => new { e.TripWalletId, e.UserId, e.Status }).HasDatabaseName("IX_FundContributions_Wallet_User_Status");
            entity.HasOne(e => e.TripWallet).WithMany().HasForeignKey(e => e.TripWalletId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.FundRequest).WithMany().HasForeignKey(e => e.FundRequestId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<ExpenseItem>(entity =>
        {
            entity.ToTable("ExpenseItems");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(12, 3);
            entity.Property(e => e.UnitAmount).HasPrecision(18, 4);
            entity.Property(e => e.TotalAmount).HasPrecision(18, 4);
            entity.Property(e => e.Category).HasMaxLength(60);
            entity.Property(e => e.AssignedUserIdsJson).HasColumnType("jsonb");
            entity.HasIndex(e => e.ExpenseId).HasDatabaseName("IX_ExpenseItems_ExpenseId");
        });

        modelBuilder.Entity<ExpenseParticipant>(entity =>
        {
            entity.ToTable("ExpenseParticipants");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ShareAmount).HasPrecision(18, 4);
            entity.Property(e => e.SharePercent).HasPrecision(9, 6);
            entity.Property(e => e.Weight).HasPrecision(12, 4);
            entity.Property(e => e.ParticipationRatio).HasPrecision(9, 6);
            entity.Property(e => e.ParticipantType).HasMaxLength(30).IsRequired();
            entity.Property(e => e.Reason).HasMaxLength(200);
            entity.HasIndex(e => new { e.ExpenseId, e.UserId }).HasDatabaseName("IX_ExpenseParticipants_ExpenseId_UserId");
        });

        modelBuilder.Entity<ExpensePaymentSource>(entity =>
        {
            entity.ToTable("ExpensePaymentSources");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SourceType).HasConversion<int>();
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.HasIndex(e => e.ExpenseId).HasDatabaseName("IX_ExpensePaymentSources_ExpenseId");
            entity.HasIndex(e => e.TripWalletId).HasDatabaseName("IX_ExpensePaymentSources_TripWalletId");
            entity.HasIndex(e => e.PaymentId).HasDatabaseName("IX_ExpensePaymentSources_PaymentId");
        });

        modelBuilder.Entity<Debt>(entity =>
        {
            entity.ToTable("Debts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.Property(e => e.SourceHash).HasMaxLength(128);
            entity.HasIndex(e => new { e.TripId, e.Status }).HasDatabaseName("IX_Debts_TripId_Status");
            entity.HasIndex(e => e.CalculationRunId).HasDatabaseName("IX_Debts_CalculationRunId");
        });

        modelBuilder.Entity<Settlement>(entity =>
        {
            entity.ToTable("Settlements");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.PaidAmount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.HasIndex(e => new { e.TripId, e.Status }).HasDatabaseName("IX_Settlements_TripId_Status");
            entity.HasIndex(e => e.DebtId).HasDatabaseName("IX_Settlements_DebtId");
            entity.HasIndex(e => e.PaymentId).HasDatabaseName("IX_Settlements_PaymentId");
        });

        modelBuilder.Entity<PaymentMethod>(entity =>
        {
            entity.ToTable("PaymentMethods");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Type).HasConversion<int>();
            entity.Property(e => e.Provider).HasConversion<int>();
            entity.Property(e => e.DisplayName).HasMaxLength(120).IsRequired();
            entity.Property(e => e.BankCode).HasMaxLength(30);
            entity.Property(e => e.BankAccountName).HasMaxLength(120);
            entity.Property(e => e.CapabilitiesJson).HasColumnType("jsonb");
            entity.Property(e => e.Status).HasConversion<int>();
            entity.HasIndex(e => new { e.UserId, e.IsDefaultReceive }).HasDatabaseName("IX_PaymentMethods_UserId_IsDefaultReceive");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.ToTable("Payments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Purpose).HasConversion<int>();
            entity.Property(e => e.Provider).HasConversion<int>();
            entity.Property(e => e.ProviderOrderId).HasMaxLength(100);
            entity.Property(e => e.ProviderTransactionId).HasMaxLength(100);
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.ReferenceCode).HasMaxLength(30).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>();
            entity.Property(e => e.FailureCode).HasMaxLength(60);
            entity.Property(e => e.FailureMessage).HasMaxLength(500);
            entity.Property(e => e.IdempotencyKey).HasMaxLength(120).IsRequired();
            entity.HasIndex(e => e.IdempotencyKey).IsUnique().HasDatabaseName("IX_Payments_IdempotencyKey");
            entity.HasIndex(e => new { e.TripId, e.ReferenceCode }).IsUnique().HasDatabaseName("IX_Payments_TripId_ReferenceCode");
            entity.HasIndex(e => e.ProviderOrderId).HasDatabaseName("IX_Payments_ProviderOrderId");
            entity.HasIndex(e => e.ProviderTransactionId).HasDatabaseName("IX_Payments_ProviderTransactionId");
        });

        modelBuilder.Entity<QRPayment>(entity =>
        {
            entity.ToTable("QRPayments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Provider).HasConversion<int>();
            entity.Property(e => e.QrType).HasConversion<int>();
            entity.Property(e => e.ProviderPayloadJson).HasColumnType("jsonb");
            entity.Property(e => e.Status).HasConversion<int>();
            entity.HasIndex(e => new { e.PaymentId, e.Provider }).HasDatabaseName("IX_QRPayments_PaymentId_Provider");
            entity.HasOne(e => e.Payment).WithMany().HasForeignKey(e => e.PaymentId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PaymentWebhookEvent>(entity =>
        {
            entity.ToTable("PaymentWebhookEvents");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Provider).HasConversion<int>();
            entity.Property(e => e.ProviderEventId).HasMaxLength(120);
            entity.Property(e => e.SignatureHash).HasMaxLength(256);
            entity.Property(e => e.PayloadJson).HasColumnType("jsonb");
            entity.Property(e => e.ProcessingStatus).HasConversion<int>();
            entity.HasIndex(e => new { e.Provider, e.ProviderEventId }).HasDatabaseName("IX_PaymentWebhookEvents_Provider_EventId");
            entity.HasIndex(e => e.PaymentId).HasDatabaseName("IX_PaymentWebhookEvents_PaymentId");
        });

        modelBuilder.Entity<TransactionHistory>(entity =>
        {
            entity.ToTable("TransactionHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.EntityType).HasMaxLength(40).IsRequired();
            entity.Property(e => e.Action).HasMaxLength(60).IsRequired();
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.Currency).HasMaxLength(3);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.MetadataJson).HasColumnType("jsonb");
            entity.HasIndex(e => new { e.TripId, e.OccurredAt }).HasDatabaseName("IX_TransactionHistories_TripId_OccurredAt");
            entity.HasIndex(e => new { e.EntityType, e.EntityId }).HasDatabaseName("IX_TransactionHistories_Entity");
        });
    }
}
