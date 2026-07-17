namespace Expense.API.Data;

internal static class DemoTripSeedData
{
    public static readonly Guid TripId = new("20000000-0000-0000-0000-000000000001");

    public static readonly DemoUser[] Users =
    [
        new(new Guid("10000000-0000-0000-0000-000000000001"), "Minh"),
        new(new Guid("10000000-0000-0000-0000-000000000002"), "Linh"),
        new(new Guid("10000000-0000-0000-0000-000000000003"), "Huy"),
        new(new Guid("10000000-0000-0000-0000-000000000004"), "Trang"),
        new(new Guid("10000000-0000-0000-0000-000000000005"), "Quang"),
        new(new Guid("10000000-0000-0000-0000-000000000006"), "Mai")
    ];

    public sealed record DemoUser(Guid Id, string NickName);
}
