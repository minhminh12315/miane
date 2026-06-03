namespace BuildingBlocks.AI.Contracts;

public sealed class TripPlanRequest
{
    public string Destination { get; set; } = string.Empty;
    public int DurationDays { get; set; }
    public decimal? Budget { get; set; }
    public string? BudgetCurrency { get; set; }
    public List<string> Preferences { get; set; } = new();
    public int NumberOfTravelers { get; set; } = 1;
}

public sealed class TripPlanSuggestion
{
    public bool IsSuccess { get; set; }
    public string? ErrorMessage { get; set; }
    public string Destination { get; set; } = string.Empty;
    public List<DayPlan> Days { get; set; } = new();
    public decimal EstimatedTotalCost { get; set; }
    public string Currency { get; set; } = "VND";
}

public sealed class DayPlan
{
    public int DayNumber { get; set; }
    public List<Activity> Activities { get; set; } = new();
    public decimal EstimatedDailyCost { get; set; }
}

public sealed class Activity
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? Location { get; set; }
    public string? TimeSlot { get; set; }
    public decimal EstimatedCost { get; set; }
}
