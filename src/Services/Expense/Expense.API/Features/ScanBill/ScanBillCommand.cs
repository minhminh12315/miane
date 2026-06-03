using BuildingBlocks.AI;
using BuildingBlocks.CQRS;
using Expense.API.Features.CreateExpense;

namespace Expense.API.Features.ScanBill;

public sealed record ScanBillCommand(
    Guid TripId,
    string TripBaseCurrency,
    Guid PaidByUserId,
    Stream ImageStream,
    string FileName,
    List<Guid> ParticipantUserIds) : ICommand<ScanBillResult>;

public sealed record ScanBillResult(
    bool IsSuccess,
    string? ErrorMessage,
    List<ScannedExpenseItem> Items,
    decimal TotalAmount,
    string Currency);

public sealed record ScannedExpenseItem(string ItemName, decimal Amount, int Quantity);

public sealed class ScanBillHandler : ICommandHandler<ScanBillCommand, ScanBillResult>
{
    private readonly IAiOcrService _ocrService;

    public ScanBillHandler(IAiOcrService ocrService)
    {
        _ocrService = ocrService;
    }

    public async Task<ScanBillResult> Handle(ScanBillCommand request, CancellationToken cancellationToken)
    {
        var result = await _ocrService.ScanBillAsync(request.ImageStream, request.FileName, cancellationToken);

        if (!result.IsSuccess)
        {
            return new ScanBillResult(false, result.ErrorMessage, new(), 0, string.Empty);
        }

        var items = result.Items.Select(i => new ScannedExpenseItem(
            i.ItemName, i.Amount, i.Quantity)).ToList();

        return new ScanBillResult(true, null, items, result.TotalAmount, result.Currency);
    }
}
