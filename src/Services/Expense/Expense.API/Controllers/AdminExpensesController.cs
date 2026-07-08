using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Expense.API.Data;

namespace Expense.API.Controllers
{
    /// <summary>
    /// Admin-only, cross-trip view of all expenses (for the admin dashboard).
    /// Regular endpoints on ExpensesController are trip-scoped by design;
    /// this is the one exception, gated behind the "Admin" role.
    /// </summary>
    [ApiController]
    [Route("expenses/admin")]
    [Authorize(Roles = "Admin")]
    public class AdminExpensesController : ControllerBase
    {
        private readonly ExpenseDbContext _db;

        public AdminExpensesController(ExpenseDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> ListAllExpenses(CancellationToken ct)
        {
            var expenses = await _db.Expenses
                .OrderByDescending(e => e.CreatedAt)
                .Select(e => new
                {
                    id = e.Id,
                    tripId = e.TripId,
                    description = e.Description,
                    amount = e.Amount,
                    currency = e.Currency,
                    convertedAmount = e.ConvertedAmount,
                    paidByUserId = e.PaidByUserId,
                    isPaidFromPool = e.IsPaidFromPool,
                    createdAt = e.CreatedAt
                })
                .ToListAsync(ct);

            return Ok(expenses);
        }
    }
}
