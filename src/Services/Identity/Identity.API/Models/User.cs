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

    }
}
