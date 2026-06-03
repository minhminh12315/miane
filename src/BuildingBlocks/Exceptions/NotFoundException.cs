namespace BuildingBlocks.Exceptions;

/// <summary>
/// Thrown when a requested entity does not exist.
/// Maps to HTTP 404 Not Found.
/// </summary>
public class NotFoundException : DomainException
{
    public NotFoundException(string entityName, object key)
        : base($"{entityName} with key '{key}' was not found.", "NOT_FOUND")
    {
    }

    public NotFoundException(string message)
        : base(message, "NOT_FOUND")
    {
    }
}
