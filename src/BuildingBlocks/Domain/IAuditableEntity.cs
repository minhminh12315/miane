namespace BuildingBlocks.Domain;

/// <summary>
/// Implemented by entities requiring a full audit trail of who created or modified them.
/// </summary>
public interface IAuditableEntity
{
    Guid? CreatedBy { get; set; }
    Guid? ModifiedBy { get; set; }
}
