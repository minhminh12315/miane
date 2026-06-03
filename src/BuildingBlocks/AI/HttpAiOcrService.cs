using BuildingBlocks.AI.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Net.Http.Json;

namespace BuildingBlocks.AI;

/// <summary>
/// HTTP-based implementation of <see cref="IAiOcrService"/> that forwards
/// image data to the Python FastAPI AI engine. Returns mock data when
/// the AI service is unavailable.
/// </summary>
public sealed class HttpAiOcrService : IAiOcrService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<HttpAiOcrService> _logger;

    public HttpAiOcrService(HttpClient httpClient, ILogger<HttpAiOcrService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<OcrBillResult> ScanBillAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default)
    {
        try
        {
            using var content = new MultipartFormDataContent();
            using var streamContent = new StreamContent(imageStream);
            content.Add(streamContent, "file", fileName);

            var response = await _httpClient.PostAsync("/api/ocr/scan", content, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<OcrBillResult>(cancellationToken: cancellationToken);
            return result ?? new OcrBillResult { IsSuccess = false, ErrorMessage = "Empty response from AI service" };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "[AI-OCR] Failed to reach AI service. Returning empty result.");
            return new OcrBillResult
            {
                IsSuccess = false,
                ErrorMessage = $"AI OCR service unavailable: {ex.Message}"
            };
        }
    }
}
