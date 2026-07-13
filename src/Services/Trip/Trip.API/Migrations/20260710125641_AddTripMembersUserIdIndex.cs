using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Trip.API.Migrations
{
    /// <inheritdoc />
    public partial class AddTripMembersUserIdIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_TripMembers_UserId",
                table: "TripMembers",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_TripMembers_UserId",
                table: "TripMembers");
        }
    }
}
