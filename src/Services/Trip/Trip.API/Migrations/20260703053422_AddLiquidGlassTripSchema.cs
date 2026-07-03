using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Trip.API.Migrations
{
    /// <inheritdoc />
    public partial class AddLiquidGlassTripSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CoverImageUrl",
                table: "Trips",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DestinationCity",
                table: "Trips",
                type: "character varying(160)",
                maxLength: 160,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DestinationCountry",
                table: "Trips",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EndDate",
                table: "Trips",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Latitude",
                table: "Trips",
                type: "numeric(9,6)",
                precision: 9,
                scale: 6,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Longitude",
                table: "Trips",
                type: "numeric(9,6)",
                precision: 9,
                scale: 6,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StartDate",
                table: "Trips",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "RoleId",
                table: "TripMembers",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TripBookings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Title = table.Column<string>(type: "character varying(220)", maxLength: 220, nullable: false),
                    ConfirmationNumber = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    StartsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    LocationName = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: true),
                    Status = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    AttachmentUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripBookings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripBookings_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripFiles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Folder = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    FileName = table.Column<string>(type: "character varying(260)", maxLength: 260, nullable: false),
                    FileUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ContentType = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: true),
                    UploadedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Permissions = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'[]'::jsonb"),
                    Tags = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'[]'::jsonb"),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripFiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripFiles_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripImages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    ImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Destination = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: true),
                    Prompt = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    CacheKey = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    IsCover = table.Column<bool>(type: "boolean", nullable: false),
                    IsGenerated = table.Column<bool>(type: "boolean", nullable: false),
                    UploadedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripImages_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripInvitations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    ShareUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Method = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RevokedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripInvitations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripInvitations_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripJoinRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    NickName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    RespondedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    RespondedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripJoinRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripJoinRequests_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripLocations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(220)", maxLength: 220, nullable: false),
                    Type = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Latitude = table.Column<decimal>(type: "numeric(9,6)", precision: 9, scale: 6, nullable: false),
                    Longitude = table.Column<decimal>(type: "numeric(9,6)", precision: 9, scale: 6, nullable: false),
                    Address = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripLocations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripLocations_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripPlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    PlanDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Title = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripPlans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripPlans_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripRoles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    RoleName = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Permissions = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'[]'::jsonb"),
                    IsSystem = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripRoles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripRoles_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripShareLinks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    Url = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RevokedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripShareLinks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripShareLinks_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripWeatherCache",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Destination = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: false),
                    ForecastDate = table.Column<DateOnly>(type: "date", nullable: false),
                    PayloadJson = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'::jsonb"),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripWeatherCache", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripWeatherCache_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripActivities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripPlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    TripId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slot = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Category = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    LocationName = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: true),
                    Latitude = table.Column<decimal>(type: "numeric(9,6)", precision: 9, scale: 6, nullable: true),
                    Longitude = table.Column<decimal>(type: "numeric(9,6)", precision: 9, scale: 6, nullable: true),
                    StartsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    ColorHex = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripActivities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripActivities_TripPlans_TripPlanId",
                        column: x => x.TripPlanId,
                        principalTable: "TripPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TripActivities_Trips_TripId",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TripRolePermissions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TripRoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    PermissionKey = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripRolePermissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripRolePermissions_TripRoles_TripRoleId",
                        column: x => x.TripRoleId,
                        principalTable: "TripRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TripMembers_RoleId",
                table: "TripMembers",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_TripActivities_Trip_Plan_Order",
                table: "TripActivities",
                columns: new[] { "TripId", "TripPlanId", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_TripActivities_TripPlanId",
                table: "TripActivities",
                column: "TripPlanId");

            migrationBuilder.CreateIndex(
                name: "IX_TripBookings_TripId_Type_StartsAt",
                table: "TripBookings",
                columns: new[] { "TripId", "Type", "StartsAt" });

            migrationBuilder.CreateIndex(
                name: "IX_TripFiles_TripId_Folder",
                table: "TripFiles",
                columns: new[] { "TripId", "Folder" });

            migrationBuilder.CreateIndex(
                name: "IX_TripImages_CacheKey",
                table: "TripImages",
                column: "CacheKey");

            migrationBuilder.CreateIndex(
                name: "IX_TripImages_TripId_IsCover",
                table: "TripImages",
                columns: new[] { "TripId", "IsCover" });

            migrationBuilder.CreateIndex(
                name: "IX_TripInvitations_Code",
                table: "TripInvitations",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripInvitations_TripId_Status",
                table: "TripInvitations",
                columns: new[] { "TripId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_TripJoinRequests_TripId_UserId_Status",
                table: "TripJoinRequests",
                columns: new[] { "TripId", "UserId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_TripLocations_TripId_Type",
                table: "TripLocations",
                columns: new[] { "TripId", "Type" });

            migrationBuilder.CreateIndex(
                name: "IX_TripPlans_TripId_PlanDate",
                table: "TripPlans",
                columns: new[] { "TripId", "PlanDate" });

            migrationBuilder.CreateIndex(
                name: "IX_TripRolePermissions_RoleId_Key",
                table: "TripRolePermissions",
                columns: new[] { "TripRoleId", "PermissionKey" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripRoles_TripId_RoleName",
                table: "TripRoles",
                columns: new[] { "TripId", "RoleName" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripShareLinks_Code",
                table: "TripShareLinks",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripShareLinks_TripId",
                table: "TripShareLinks",
                column: "TripId");

            migrationBuilder.CreateIndex(
                name: "IX_TripWeatherCache_TripId_ForecastDate",
                table: "TripWeatherCache",
                columns: new[] { "TripId", "ForecastDate" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_TripMembers_TripRoles_RoleId",
                table: "TripMembers",
                column: "RoleId",
                principalTable: "TripRoles",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TripMembers_TripRoles_RoleId",
                table: "TripMembers");

            migrationBuilder.DropTable(
                name: "TripActivities");

            migrationBuilder.DropTable(
                name: "TripBookings");

            migrationBuilder.DropTable(
                name: "TripFiles");

            migrationBuilder.DropTable(
                name: "TripImages");

            migrationBuilder.DropTable(
                name: "TripInvitations");

            migrationBuilder.DropTable(
                name: "TripJoinRequests");

            migrationBuilder.DropTable(
                name: "TripLocations");

            migrationBuilder.DropTable(
                name: "TripRolePermissions");

            migrationBuilder.DropTable(
                name: "TripShareLinks");

            migrationBuilder.DropTable(
                name: "TripWeatherCache");

            migrationBuilder.DropTable(
                name: "TripPlans");

            migrationBuilder.DropTable(
                name: "TripRoles");

            migrationBuilder.DropIndex(
                name: "IX_TripMembers_RoleId",
                table: "TripMembers");

            migrationBuilder.DropColumn(
                name: "CoverImageUrl",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "DestinationCity",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "DestinationCountry",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "EndDate",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "StartDate",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "RoleId",
                table: "TripMembers");
        }
    }
}
