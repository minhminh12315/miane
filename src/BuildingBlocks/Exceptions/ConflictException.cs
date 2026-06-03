namespace BuildingBlocks.Exceptions;

/// <summary>
/// Thrown when an operation would produce a duplicate or conflicting state.
/// Maps to HTTP 409 Conflict.
/// </summary>
public class ConflictException : DomainException
{
    public ConflictException(string message)
        : base(message, "CONFLICT")
    {
    }

    public ConflictException(string entityName, object key)
        : base($"{entityName} with key '{key}' already exists.", "CONFLICT")
    {
    }
}
