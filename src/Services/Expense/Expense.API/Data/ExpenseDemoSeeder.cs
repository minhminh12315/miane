using Expense.API.Domain.Entities;
using Expense.API.Domain.Enums;
using Expense.API.Services;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace Expense.API.Data;

public static class ExpenseDemoSeeder
{
    private const string Currency = "VND";
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        var environment = services.GetRequiredService<IHostEnvironment>();
        if (!environment.IsDevelopment())
        {
            return;
        }

        var dbContext = services.GetRequiredService<ExpenseDbContext>();
        var accountProtector = services.GetRequiredService<PaymentAccountProtector>();

        var expenses = BuildExpenses();
        foreach (var expense in expenses)
        {
            if (!await dbContext.Expenses.AnyAsync(e => e.Id == expense.Id, ct))
            {
                await dbContext.Expenses.AddAsync(expense, ct);
            }
        }

        var debtRecords = BuildDebtRecords();
        foreach (var debtRecord in debtRecords)
        {
            if (!await dbContext.DebtRecords.AnyAsync(d => d.Id == debtRecord.Id, ct))
            {
                await dbContext.DebtRecords.AddAsync(debtRecord, ct);
            }
        }

        await SeedPaymentMethodsAsync(dbContext, accountProtector, ct);
        await SeedTripWalletAsync(dbContext, ct);

        await dbContext.SaveChangesAsync(ct);
    }

    private static List<ExpenseEntity> BuildExpenses()
    {
        return
        [
            CreateEqualExpense(
                new Guid("30000000-0000-0000-0000-000000000001"),
                1,
                "Ve may bay khu hoi",
                "Ve may bay khu hoi Ha Noi - Da Nang cho ca nhom",
                "Transport",
                7_200_000m,
                DemoTripSeedData.Users[0].Id,
                paidBack: false,
                createdAt: new DateTime(2026, 8, 8, 9, 0, 0, DateTimeKind.Utc)),

            CreateEqualExpense(
                new Guid("30000000-0000-0000-0000-000000000002"),
                2,
                "Khach san 4 dem",
                "Khach san gan bien My Khe cho 6 thanh vien",
                "Lodging",
                9_600_000m,
                DemoTripSeedData.Users[1].Id,
                paidBack: false,
                createdAt: new DateTime(2026, 8, 8, 15, 30, 0, DateTimeKind.Utc)),

            CreateEqualExpense(
                new Guid("30000000-0000-0000-0000-000000000003"),
                3,
                "Thue xe di Ba Na Hills",
                "Thue xe rieng di Ba Na Hills trong ngay",
                "Transport",
                1_800_000m,
                DemoTripSeedData.Users[2].Id,
                paidBack: false,
                createdAt: new DateTime(2026, 8, 9, 7, 30, 0, DateTimeKind.Utc)),

            CreateEqualExpense(
                new Guid("30000000-0000-0000-0000-000000000004"),
                4,
                "Bua toi hai san My Khe",
                "Bua toi hai san My Khe da duoc cac thanh vien thanh toan lai",
                "Food",
                3_000_000m,
                DemoTripSeedData.Users[3].Id,
                paidBack: true,
                createdAt: new DateTime(2026, 8, 9, 20, 15, 0, DateTimeKind.Utc))
        ];
    }

    private static ExpenseEntity CreateEqualExpense(
        Guid expenseId,
        int expenseIndex,
        string title,
        string description,
        string category,
        decimal amount,
        Guid paidByUserId,
        bool paidBack,
        DateTime createdAt)
    {
        var shareAmount = Math.Round(amount / DemoTripSeedData.Users.Length, 4);
        var expense = new ExpenseEntity
        {
            Id = expenseId,
            TripId = DemoTripSeedData.TripId,
            Title = title,
            Description = description,
            Category = category,
            Amount = amount,
            Currency = Currency,
            ConvertedAmount = amount,
            ExchangeRate = 1m,
            PaidByUserId = paidByUserId,
            SplitType = SplitType.Equal,
            Status = ExpenseStatus.Posted,
            PaidAt = createdAt,
            CreatedAt = createdAt,
            IsPaidFromPool = false
        };

        for (var i = 0; i < DemoTripSeedData.Users.Length; i++)
        {
            var user = DemoTripSeedData.Users[i];
            expense.AddSplit(new ExpenseSplit
            {
                Id = DemoSplitId(expenseIndex, i + 1),
                ExpenseId = expenseId,
                UserId = user.Id,
                Amount = shareAmount,
                IsPaid = paidBack
            });
            expense.AddParticipant(new ExpenseParticipant
            {
                Id = DemoParticipantId(expenseIndex, i + 1),
                ExpenseId = expenseId,
                UserId = user.Id,
                ShareAmount = shareAmount,
                ParticipantType = "adult",
                ParticipationRatio = 1
            });
        }

        return expense;
    }

    private static List<DebtRecord> BuildDebtRecords()
    {
        return
        [
            CreateDebt(new Guid("30000000-0000-0000-0000-000000000101"), DemoTripSeedData.Users[2].Id, DemoTripSeedData.Users[0].Id, 1_200_000m, false),
            CreateDebt(new Guid("30000000-0000-0000-0000-000000000102"), DemoTripSeedData.Users[4].Id, DemoTripSeedData.Users[1].Id, 1_600_000m, false),
            CreateDebt(new Guid("30000000-0000-0000-0000-000000000103"), DemoTripSeedData.Users[5].Id, DemoTripSeedData.Users[1].Id, 1_600_000m, false),
            CreateDebt(new Guid("30000000-0000-0000-0000-000000000104"), DemoTripSeedData.Users[3].Id, DemoTripSeedData.Users[2].Id, 300_000m, false),
            CreateDebt(new Guid("30000000-0000-0000-0000-000000000105"), DemoTripSeedData.Users[0].Id, DemoTripSeedData.Users[3].Id, 500_000m, true)
        ];
    }

    private static DebtRecord CreateDebt(Guid id, Guid fromUserId, Guid toUserId, decimal amount, bool settled)
    {
        return new DebtRecord
        {
            Id = id,
            TripId = DemoTripSeedData.TripId,
            FromUserId = fromUserId,
            ToUserId = toUserId,
            Amount = amount,
            Currency = Currency,
            IsSettled = settled,
            SettledAt = settled ? new DateTime(2026, 8, 10, 10, 0, 0, DateTimeKind.Utc) : null,
            CreatedAt = new DateTime(2026, 8, 10, 9, 0, 0, DateTimeKind.Utc)
        };
    }

    private static async Task SeedPaymentMethodsAsync(
        ExpenseDbContext dbContext,
        PaymentAccountProtector accountProtector,
        CancellationToken ct)
    {
        var banks = new[]
        {
            new DemoBank("970436", "VCB", "Vietcombank", "VCB", "https://api.vietqr.io/img/VCB.png"),
            new DemoBank("970407", "TCB", "Techcombank", "TCB", "https://api.vietqr.io/img/TCB.png"),
            new DemoBank("970422", "MBB", "MB Bank", "MB", "https://api.vietqr.io/img/MBB.png"),
            new DemoBank("970416", "ACB", "ACB", "ACB", "https://api.vietqr.io/img/ACB.png"),
            new DemoBank("970418", "BIDV", "BIDV", "BIDV", "https://api.vietqr.io/img/BIDV.png"),
            new DemoBank("970415", "ICB", "VietinBank", "VietinBank", "https://api.vietqr.io/img/ICB.png")
        };

        var accountNames = new[]
        {
            "NGUYEN ANH MINH",
            "TRAN GIA LINH",
            "LE QUOC HUY",
            "PHAM THU TRANG",
            "HOANG MINH QUANG",
            "DO NGOC MAI"
        };

        for (var i = 0; i < DemoTripSeedData.Users.Length; i++)
        {
            var user = DemoTripSeedData.Users[i];
            var bank = banks[i % banks.Length];
            var accountNumber = $"1900{(i + 1):00000000}";

            var paymentMethod = await dbContext.PaymentMethods
                .FirstOrDefaultAsync(method =>
                    method.UserId == user.Id &&
                    method.Type == PaymentMethodType.BankAccount &&
                    method.Provider == PaymentProvider.VietQr,
                    ct);

            if (paymentMethod is null)
            {
                paymentMethod = new PaymentMethod
                {
                    Id = DemoPaymentMethodId(i + 1),
                    UserId = user.Id,
                    Type = PaymentMethodType.BankAccount,
                    Provider = PaymentProvider.VietQr
                };
                await dbContext.PaymentMethods.AddAsync(paymentMethod, ct);
            }

            paymentMethod.DisplayName = $"{bank.ShortName} *{accountNumber[^4..]}";
            paymentMethod.BankCode = bank.Bin;
            paymentMethod.BankAccountNoEncrypted = accountProtector.Protect(accountNumber);
            paymentMethod.BankAccountName = accountNames[i];
            paymentMethod.IsDefaultReceive = true;
            paymentMethod.Status = PaymentMethodStatus.Active;
            paymentMethod.CapabilitiesJson = JsonSerializer.Serialize(new
            {
                bankBin = bank.Bin,
                vietQrBankCode = bank.Code,
                bankName = bank.Name,
                bankShortName = bank.ShortName,
                bankLogoUrl = bank.LogoUrl,
                transferSupported = true,
                lookupSupported = true,
                verifiedAtUtc = DateTime.UtcNow
            }, JsonOptions);
            paymentMethod.UpdatedAt = DateTime.UtcNow;
        }
    }

    private static async Task SeedTripWalletAsync(ExpenseDbContext dbContext, CancellationToken ct)
    {
        var wallet = await dbContext.TripWallets
            .FirstOrDefaultAsync(item => item.TripId == DemoTripSeedData.TripId, ct);

        if (wallet is null)
        {
            wallet = new TripWallet
            {
                Id = new Guid("30000000-0000-0000-0000-000000000201"),
                TripId = DemoTripSeedData.TripId,
                Name = "Da Nang trip fund",
                Currency = Currency,
                CurrentCustodianUserId = DemoTripSeedData.Users[0].Id,
                Status = WalletStatus.Active
            };
            await dbContext.TripWallets.AddAsync(wallet, ct);
        }
        else
        {
            wallet.CurrentCustodianUserId ??= DemoTripSeedData.Users[0].Id;
            wallet.Status = WalletStatus.Active;
        }

        for (var i = 0; i < DemoTripSeedData.Users.Length; i++)
        {
            var user = DemoTripSeedData.Users[i];
            var exists = await dbContext.WalletMembers
                .AnyAsync(member =>
                    member.TripWalletId == wallet.Id &&
                    member.UserId == user.Id,
                    ct);

            if (exists)
            {
                continue;
            }

            await dbContext.WalletMembers.AddAsync(new WalletMember
            {
                Id = DemoWalletMemberId(i + 1),
                TripWalletId = wallet.Id,
                UserId = user.Id,
                Role = user.Id == wallet.CurrentCustodianUserId
                    ? WalletMemberRole.Custodian
                    : WalletMemberRole.Member,
                IsActive = true
            }, ct);
        }
    }

    private static Guid DemoSplitId(int expenseIndex, int userIndex) =>
        new($"30000000-0000-0000-0000-00000000{expenseIndex:00}{userIndex:00}");

    private static Guid DemoParticipantId(int expenseIndex, int userIndex) =>
        new($"30000000-0000-0000-0000-00000001{expenseIndex:00}{userIndex:00}");

    private static Guid DemoPaymentMethodId(int userIndex) =>
        new($"30000000-0000-0000-0000-0000000200{userIndex:00}");

    private static Guid DemoWalletMemberId(int userIndex) =>
        new($"30000000-0000-0000-0000-0000000210{userIndex:00}");

    private sealed record DemoBank(
        string Bin,
        string Code,
        string Name,
        string ShortName,
        string LogoUrl);
}
