using BuildingBlocks.AI.Contracts;

namespace BuildingBlocks.AI;

/// <summary>
/// Interface for AI-powered OCR bill scanning. Implementation talks to the
/// Python FastAPI service via HTTP.
/// </summary>
public interface IAiOcrService
{
    Task<OcrBillResult> ScanBillAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default);
}
