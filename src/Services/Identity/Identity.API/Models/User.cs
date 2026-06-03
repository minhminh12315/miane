using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Identity.API.Models
{
    [Index(nameof(Email), IsUnique = true)]
    public class User : IdentityUser<Guid>
    {
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }

        // This flag very important for distinguishing between staff (App/Admin) login flows
        // And customer (Web Client)
        public bool IsEmployee { get; set; } = false;
        
        // Link with customer code (if have)
        public string? EmployeeId { get; set; }

        public DateTime CreateAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// 0 = MIANE Basic, 1 = MIANE Pro.
        /// Basic: max 2 active trips, max 7 members per trip.
        /// Pro: unlimited trips and members.
        /// </summary>
        public int UserTier { get; set; } = 0;

        /// <summary>
        /// JSON array of TripIds that have an active Trip Pass,
        /// overriding the 7-member limit for those specific trips.
        /// </summary>
        public string? TripPassTripIds { get; set; }

    }
}
