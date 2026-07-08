using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Trip.API.Data;

namespace Trip.API.Controllers
{
    /// <summary>
    /// Admin-only, cross-user view of all trips (for the admin dashboard).
    /// Regular endpoints on TripsController are self-scoped by design; this
    /// is the one exception, gated behind the "Admin" role.
    /// </summary>
    [ApiController]
    [Route("trips/admin")]
    [Authorize(Roles = "Admin")]
    public class AdminTripsController : ControllerBase
    {
        private readonly TripDbContext _db;

        public AdminTripsController(TripDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> ListAllTrips(CancellationToken ct)
        {
            var trips = await _db.Trips
                .OrderByDescending(t => t.CreatedAt)
                .Select(t => new
                {
                    id = t.Id,
                    name = t.Name,
                    description = t.Description,
                    inviteCode = t.InviteCode,
                    baseCurrency = t.BaseCurrency,
                    status = t.Status.ToString(),
                    createdByUserId = t.CreatedByUserId,
                    memberCount = t.Members.Count,
                    createdAt = t.CreatedAt
                })
                .ToListAsync(ct);

            return Ok(trips);
        }
    }
}
