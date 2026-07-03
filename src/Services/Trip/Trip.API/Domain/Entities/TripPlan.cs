using BuildingBlocks.Domain;

namespace Trip.API.Domain.Entities;

public class TripPlan : BaseEntity
{
    private readonly List<TripActivity> _activities = new();

    public Guid TripId { get; set; }
    public DateOnly PlanDate { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public int SortOrder { get; set; }

    public TripEntity Trip { get; set; } = null!;
    public IReadOnlyCollection<TripActivity> Activities => _activities.AsReadOnly();

    public void AddActivity(TripActivity activity)
    {
        _activities.Add(activity);
    }
}
