namespace Identity.API.Data;

internal static class DemoTripSeedData
{
    public const string Password = "Demo@123";

    public static readonly DemoUser[] Users =
    [
        new(new Guid("10000000-0000-0000-0000-000000000001"), "demo.danang.minh@miane.local", "Nguyen Anh Minh"),
        new(new Guid("10000000-0000-0000-0000-000000000002"), "demo.danang.linh@miane.local", "Tran Gia Linh"),
        new(new Guid("10000000-0000-0000-0000-000000000003"), "demo.danang.huy@miane.local", "Le Quoc Huy"),
        new(new Guid("10000000-0000-0000-0000-000000000004"), "demo.danang.trang@miane.local", "Pham Thu Trang"),
        new(new Guid("10000000-0000-0000-0000-000000000005"), "demo.danang.quang@miane.local", "Hoang Minh Quang"),
        new(new Guid("10000000-0000-0000-0000-000000000006"), "demo.danang.mai@miane.local", "Do Ngoc Mai")
    ];

    public sealed record DemoUser(Guid Id, string Email, string FullName);
}
