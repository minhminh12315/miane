using BuildingBlocks.Caching;
using BuildingBlocks.Exceptions;
using Microsoft.Extensions.Options;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Expense.API.Services;

public interface IVietQrClient
{
    Task<IReadOnlyList<VietQrBank>> GetBanksAsync(CancellationToken ct = default);
    Task<VietQrGenerateResult> GenerateAsync(VietQrGenerateRequest request, CancellationToken ct = default);
}

public sealed class VietQrClient : IVietQrClient
{
    private const string BanksCacheKey = "vietqr:banks:v2";

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly HttpClient _httpClient;
    private readonly ICacheService _cache;
    private readonly VietQrOptions _options;
    private readonly ILogger<VietQrClient> _logger;

    public VietQrClient(
        HttpClient httpClient,
        ICacheService cache,
        IOptions<VietQrOptions> options,
        ILogger<VietQrClient> logger)
    {
        _httpClient = httpClient;
        _cache = cache;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<IReadOnlyList<VietQrBank>> GetBanksAsync(CancellationToken ct = default)
    {
        try
        {
            var cached = await _cache.GetAsync<List<VietQrBank>>(BanksCacheKey);
            if (cached is { Count: > 0 })
            {
                return cached;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not read VietQR bank list from cache.");
        }

        var envelope = await _httpClient.GetFromJsonAsync<VietQrEnvelope<List<VietQrBankDto>>>(
            "v2/banks",
            JsonOptions,
            ct);

        if (envelope?.Code != "00" || envelope.Data is null)
        {
            throw new DomainException(
                $"Khong the lay danh sach ngan hang VietQR: {envelope?.Desc ?? "unknown error"}.",
                "VIETQR_BANKS_FAILED");
        }

        var banks = envelope.Data
            .Where(bank => !string.IsNullOrWhiteSpace(bank.Bin))
            .Select(bank => new VietQrBank(
                bank.Id,
                bank.Name ?? string.Empty,
                bank.Code ?? string.Empty,
                bank.Bin ?? string.Empty,
                string.IsNullOrWhiteSpace(bank.ShortName) ? bank.Code ?? string.Empty : bank.ShortName!,
                bank.Logo ?? string.Empty,
                bank.TransferSupported == 1,
                bank.LookupSupported == 1,
                bank.SwiftCode))
            .OrderBy(bank => bank.ShortName)
            .ToList();

        try
        {
            await _cache.SetAsync(BanksCacheKey, banks, TimeSpan.FromHours(Math.Max(1, _options.BanksCacheHours)));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not cache VietQR bank list.");
        }

        return banks;
    }

    public async Task<VietQrGenerateResult> GenerateAsync(VietQrGenerateRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ClientId) || string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            throw new DomainException(
                "VietQR chua duoc cau hinh. Hay them VIETQR_CLIENT_ID va VIETQR_API_KEY vao moi truong backend.",
                "VIETQR_NOT_CONFIGURED");
        }

        using var message = new HttpRequestMessage(HttpMethod.Post, "v2/generate")
        {
            Content = JsonContent.Create(new
            {
                accountNo = request.AccountNumber,
                accountName = request.AccountName,
                acqId = request.AcqId,
                amount = request.Amount,
                addInfo = request.AddInfo,
                format = string.IsNullOrWhiteSpace(request.Format) ? _options.DefaultFormat : request.Format,
                template = string.IsNullOrWhiteSpace(request.Template) ? _options.DefaultTemplate : request.Template
            }, options: JsonOptions)
        };
        message.Headers.TryAddWithoutValidation("x-client-id", _options.ClientId);
        message.Headers.TryAddWithoutValidation("x-api-key", _options.ApiKey);

        using var response = await _httpClient.SendAsync(message, ct);
        var body = await response.Content.ReadAsStringAsync(ct);
        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "VietQR generate request failed with status {StatusCode}: {Body}",
                (int)response.StatusCode,
                body);
            throw new DomainException("Khong the tao ma VietQR luc nay.", "VIETQR_GENERATE_FAILED");
        }

        var envelope = JsonSerializer.Deserialize<VietQrEnvelope<VietQrGenerateDataDto>>(body, JsonOptions);
        if (envelope?.Code != "00" || envelope.Data is null)
        {
            throw new DomainException(
                $"Khong the tao ma VietQR: {envelope?.Desc ?? "unknown error"}.",
                "VIETQR_GENERATE_FAILED");
        }

        return new VietQrGenerateResult(
            envelope.Data.AcqId,
            envelope.Data.AccountName ?? request.AccountName,
            envelope.Data.QrCode ?? string.Empty,
            envelope.Data.QrDataUrl ?? string.Empty,
            envelope.Desc ?? "Gen VietQR successful!");
    }

    private sealed class VietQrEnvelope<T>
    {
        public string? Code { get; set; }
        public string? Desc { get; set; }
        public T? Data { get; set; }
    }

    private sealed class VietQrBankDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Code { get; set; }
        public string? Bin { get; set; }
        public string? ShortName { get; set; }
        public string? Logo { get; set; }
        public int TransferSupported { get; set; }
        public int LookupSupported { get; set; }

        [JsonPropertyName("swift_code")]
        public string? SwiftCode { get; set; }
    }

    private sealed class VietQrGenerateDataDto
    {
        [JsonPropertyName("acpId")]
        public int AcqId { get; set; }

        [JsonPropertyName("acqId")]
        public int AlternateAcqId
        {
            set => AcqId = value;
        }

        public string? AccountName { get; set; }
        public string? QrCode { get; set; }
        public string? QrDataUrl { get; set; }
    }
}

public sealed record VietQrBank(
    int Id,
    string Name,
    string Code,
    string Bin,
    string ShortName,
    string Logo,
    bool TransferSupported,
    bool LookupSupported,
    string? SwiftCode);

public sealed record VietQrGenerateRequest(
    string AccountNumber,
    string AccountName,
    int AcqId,
    long Amount,
    string AddInfo,
    string? Format,
    string? Template);

public sealed record VietQrGenerateResult(
    int AcqId,
    string AccountName,
    string QrCode,
    string QrDataUrl,
    string Description);
