using Microsoft.EntityFrameworkCore;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;

namespace Trip.API.Data;

public static class TripDemoSeeder
{
    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        var environment = services.GetRequiredService<IHostEnvironment>();
        if (!environment.IsDevelopment())
        {
            return;
        }

        var dbContext = services.GetRequiredService<TripDbContext>();
        var trip = await dbContext.Trips
            .Include(t => t.Members)
            .Include(t => t.ShareLinks)
            .FirstOrDefaultAsync(t => t.Id == DemoTripSeedData.TripId, ct);

        if (trip is null)
        {
            trip = new TripEntity
            {
                Id = DemoTripSeedData.TripId,
                Name = "Da Nang Food & Beach Trip",
                Description = "Chuyen di mau 5 ngay o Da Nang de test chia chi phi, cong no va thanh toan VietQR.",
                InviteCode = "DANANG26",
                BaseCurrency = "VND",
                CreatedByUserId = DemoTripSeedData.Users[0].Id,
                Status = TripStatus.Active,
                DestinationCity = "Da Nang",
                DestinationCountry = "Vietnam",
                Latitude = 16.047079m,
                Longitude = 108.206230m,
                StartDate = new DateTime(2026, 8, 8, 0, 0, 0, DateTimeKind.Utc),
                EndDate = new DateTime(2026, 8, 12, 0, 0, 0, DateTimeKind.Utc),
                CoverImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80",
                CreatedAt = new DateTime(2026, 7, 16, 0, 0, 0, DateTimeKind.Utc)
            };

            await dbContext.Trips.AddAsync(trip, ct);
        }

        foreach (var user in DemoTripSeedData.Users)
        {
            if (trip.Members.Any(m => m.UserId == user.Id))
            {
                continue;
            }

            trip.AddMember(new TripMember
            {
                Id = DemoMemberId(user.Id),
                TripId = DemoTripSeedData.TripId,
                UserId = user.Id,
                Role = user.Id == DemoTripSeedData.Users[0].Id ? MemberRole.Owner : MemberRole.Member,
                NickName = user.NickName,
                UserTier = 0,
                JoinedAt = new DateTime(2026, 7, 16, 1, 0, 0, DateTimeKind.Utc)
            });
        }

        if (!trip.ShareLinks.Any(s => s.Code == "DANANG26"))
        {
            trip.AddShareLink(new TripShareLink
            {
                Id = DemoTripSeedData.ShareLinkId,
                TripId = DemoTripSeedData.TripId,
                Code = "DANANG26",
                Url = "https://miane.app/trip/DANANG26",
                Type = TripShareLinkType.Invitation,
                CreatedByUserId = DemoTripSeedData.Users[0].Id,
                IsActive = true,
                CreatedAt = new DateTime(2026, 7, 16, 1, 5, 0, DateTimeKind.Utc)
            });
        }

        await dbContext.SaveChangesAsync(ct);
    }

    private static Guid DemoMemberId(Guid userId)
    {
        var index = Array.FindIndex(DemoTripSeedData.Users, user => user.Id == userId) + 1;
        return new Guid($"20000000-0000-0000-0000-00000000020{index}");
    }
}
