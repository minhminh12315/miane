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
            entity.Property(e => e.Description).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Amount).HasPrecision(18, 4);
            entity.Property(e => e.ConvertedAmount).HasPrecision(18, 4);
            entity.Property(e => e.ExchangeRate).HasPrecision(18, 8);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.SplitType).HasConversion<int>();
            entity.HasIndex(e => e.TripId).HasDatabaseName("IX_Expenses_TripId");
            entity.HasMany(e => e.Splits).WithOne(s => s.Expense).HasForeignKey(s => s.ExpenseId).OnDelete(DeleteBehavior.Cascade);
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
    }
}
