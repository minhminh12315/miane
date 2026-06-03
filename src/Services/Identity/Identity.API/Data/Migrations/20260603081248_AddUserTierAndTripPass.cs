using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Identity.API.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddUserTierAndTripPass : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TripPassTripIds",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UserTier",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TripPassTripIds",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "UserTier",
                table: "Users");
        }
    }
}
