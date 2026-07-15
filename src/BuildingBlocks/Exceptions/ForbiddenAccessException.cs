namespace BuildingBlocks.Exceptions;

/// <summary>
/// Thrown when the current user lacks permission for the requested operation.
/// Maps to HTTP 403 Forbidden.
/// </summary>
public class ForbiddenAccessException : DomainException
{
    public ForbiddenAccessException(string message = "Bạn không có quyền thực hiện thao tác này.")
        : base(message, "FORBIDDEN")
    {
    }
}
