namespace BuildingBlocks.Exceptions;

/// <summary>
/// Thrown when the current user lacks permission for the requested operation.
/// Maps to HTTP 403 Forbidden.
/// </summary>
public class ForbiddenAccessException : DomainException
{
    public ForbiddenAccessException(string message = "You do not have permission to perform this action.")
        : base(message, "FORBIDDEN")
    {
    }
}
