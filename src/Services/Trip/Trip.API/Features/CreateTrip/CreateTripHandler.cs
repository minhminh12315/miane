using BuildingBlocks.CQRS;
using BuildingBlocks.EventBus;
using System.Text.Json;
using Trip.API.Data.Repositories;
using Trip.API.Domain.Entities;
using Trip.API.Domain.Enums;
using Trip.API.IntegrationEvents;

namespace Trip.API.Features.CreateTrip;

public sealed class CreateTripHandler : ICommandHandler<CreateTripCommand, CreateTripResult>
{
    private readonly ITripRepository _tripRepository;
    private readonly IEventBus _eventBus;

    public CreateTripHandler(ITripRepository tripRepository, IEventBus eventBus)
    {
        _tripRepository = tripRepository;
        _eventBus = eventBus;
    }

    public async Task<CreateTripResult> Handle(CreateTripCommand request, CancellationToken cancellationToken)
    {
        var trip = new TripEntity
        {
            Name = request.Name,
            Description = request.Description,
            BaseCurrency = request.BaseCurrency.ToUpperInvariant(),
            CreatedByUserId = request.UserId,
            InviteCode = TripEntity.GenerateInviteCode(),
            Status = TripStatus.Active,
            DestinationCity = FirstNonEmpty(request.DestinationCity, request.Destination),
            DestinationCountry = request.DestinationCountry,
            Latitude = ToDecimal(request.Latitude),
            Longitude = ToDecimal(request.Longitude),
            StartDate = NormalizeUtcDate(request.StartDate),
            EndDate = NormalizeUtcDate(request.EndDate),
            CoverImageUrl = request.CoverImageUrl
        };

        var ownerRole = CreateSystemRole(
            trip.Id,
            "Owner",
            "Full control of this trip.",
            TripPermissions.All);

        var adminRole = CreateSystemRole(
            trip.Id,
            "Admin",
            "Can manage planning, members, bookings and files.",
            TripPermissions.Admin);

        var financeRole = CreateSystemRole(
            trip.Id,
            "Finance",
            "Can manage expenses and settlements.",
            TripPermissions.Finance);

        var plannerRole = CreateSystemRole(
            trip.Id,
            "Planner",
            "Can manage itinerary, bookings and map planning.",
            TripPermissions.Planner);

        var photographerRole = CreateSystemRole(
            trip.Id,
            "Photographer",
            "Can manage gallery, memories and trip files.",
            TripPermissions.Photographer);

        var memberRole = CreateSystemRole(
            trip.Id,
            "Member",
            "Can view shared trip information.",
            TripPermissions.Member);

        trip.AddRole(ownerRole);
        trip.AddRole(adminRole);
        trip.AddRole(financeRole);
        trip.AddRole(plannerRole);
        trip.AddRole(photographerRole);
        trip.AddRole(memberRole);

        // Creator is automatically the owner
        var ownerMember = new TripMember
        {
            TripId = trip.Id,
            UserId = request.UserId,
            RoleId = ownerRole.Id,
            Role = MemberRole.Owner,
            UserTier = request.UserTier,
            JoinedAt = DateTime.UtcNow
        };

        trip.AddMember(ownerMember);

        var shareUrl = $"https://miane.app/trip/{trip.InviteCode}";
        trip.AddInvitation(new TripInvitation
        {
            TripId = trip.Id,
            Code = trip.InviteCode,
            ShareUrl = shareUrl,
            Method = TripInvitationMethod.Code,
            Status = TripInvitationStatus.Active,
            CreatedByUserId = request.UserId
        });
        trip.AddShareLink(new TripShareLink
        {
            TripId = trip.Id,
            Code = trip.InviteCode,
            Url = shareUrl,
            Type = TripShareLinkType.Invitation,
            CreatedByUserId = request.UserId,
            IsActive = true
        });

        if (!string.IsNullOrWhiteSpace(request.CoverImageUrl))
        {
            trip.AddImage(new TripImage
            {
                TripId = trip.Id,
                ImageUrl = request.CoverImageUrl,
                Destination = FirstNonEmpty(request.Destination, request.DestinationCity),
                IsCover = true,
                IsGenerated = false,
                UploadedByUserId = request.UserId
            });
        }

        await _tripRepository.AddAsync(trip, cancellationToken);
        await _tripRepository.SaveChangesAsync(cancellationToken);

        await _eventBus.PublishAsync(new TripCreatedEvent
        {
            TripId = trip.Id,
            TripName = trip.Name,
            CreatedByUserId = request.UserId,
            InviteCode = trip.InviteCode
        }, cancellationToken);

        return new CreateTripResult(trip.Id, trip.InviteCode, shareUrl);
    }

    private static TripRole CreateSystemRole(
        Guid tripId,
        string roleName,
        string description,
        IReadOnlyCollection<string> permissions)
    {
        var role = new TripRole
        {
            TripId = tripId,
            RoleName = roleName,
            Description = description,
            Permissions = JsonSerializer.Serialize(permissions),
            IsSystem = true
        };

        foreach (var permission in permissions)
        {
            role.AddPermission(permission);
        }

        return role;
    }

    private static decimal? ToDecimal(double? value) =>
        value.HasValue ? Convert.ToDecimal(value.Value) : null;

    private static DateTime? NormalizeUtcDate(DateTime? value)
    {
        if (!value.HasValue) return null;

        return value.Value.Kind switch
        {
            DateTimeKind.Utc => value.Value,
            DateTimeKind.Local => value.Value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value.Value, DateTimeKind.Utc)
        };
    }

    private static string? FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(value => !string.IsNullOrWhiteSpace(value))?.Trim();
}

internal static class TripPermissions
{
    public const string ManageMembers = "manage_members";
    public const string ManageExpense = "manage_expense";
    public const string ManageItinerary = "manage_itinerary";
    public const string ManageFiles = "manage_files";
    public const string ManageBooking = "manage_booking";
    public const string ManageWeather = "manage_weather";
    public const string ManageSettings = "manage_settings";
    public const string DeleteTrip = "delete_trip";
    public const string ViewTrip = "view_trip";
    public const string ManageMap = "manage_map";
    public const string ManageMemories = "manage_memories";

    public static readonly IReadOnlyCollection<string> All =
    [
        ManageMembers,
        ManageExpense,
        ManageItinerary,
        ManageFiles,
        ManageBooking,
        ManageWeather,
        ManageSettings,
        DeleteTrip,
        ViewTrip,
        ManageMap,
        ManageMemories
    ];

    public static readonly IReadOnlyCollection<string> Admin =
    [
        ManageMembers,
        ManageExpense,
        ManageItinerary,
        ManageFiles,
        ManageBooking,
        ManageWeather,
        ManageSettings,
        ViewTrip,
        ManageMap,
        ManageMemories
    ];

    public static readonly IReadOnlyCollection<string> Finance =
    [
        ManageExpense,
        ViewTrip
    ];

    public static readonly IReadOnlyCollection<string> Planner =
    [
        ManageItinerary,
        ManageBooking,
        ManageWeather,
        ViewTrip,
        ManageMap
    ];

    public static readonly IReadOnlyCollection<string> Photographer =
    [
        ManageFiles,
        ViewTrip,
        ManageMemories
    ];

    public static readonly IReadOnlyCollection<string> Member =
    [
        ViewTrip
    ];
}
