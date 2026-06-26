using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetFinancialStats;

public class GetFinancialStatsQueryHandler : IRequestHandler<GetFinancialStatsQuery, ApiResponse<FinancialStatsDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetFinancialStatsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<FinancialStatsDto>> Handle(GetFinancialStatsQuery request, CancellationToken cancellationToken)
    {
        var totalRevenue = await _dbContext.Transactions
            .AsNoTracking()
            .Where(t => t.Status == PaymentStatus.Paid)
            .SumAsync(t => t.PlatformFee, cancellationToken);

        var totalVolume = await _dbContext.Transactions
            .AsNoTracking()
            .Where(t => t.Status == PaymentStatus.Paid)
            .SumAsync(t => t.Amount, cancellationToken);

        var totalTransactions = await _dbContext.Transactions
            .AsNoTracking()
            .CountAsync(cancellationToken);

        var paidTransactions = await _dbContext.Transactions
            .AsNoTracking()
            .CountAsync(t => t.Status == PaymentStatus.Paid, cancellationToken);

        var pendingPayouts = await _dbContext.DoctorWallets
            .AsNoTracking()
            .SumAsync(w => w.PendingBalance, cancellationToken);

        var totalWithdrawn = await _dbContext.DoctorWallets
            .AsNoTracking()
            .SumAsync(w => w.WithdrawnAmount, cancellationToken);

        var dto = new FinancialStatsDto(
            TotalRevenue: totalRevenue,
            TotalVolume: totalVolume,
            TotalTransactions: totalTransactions,
            PaidTransactions: paidTransactions,
            PendingPayouts: pendingPayouts,
            TotalWithdrawn: totalWithdrawn
        );

        return ApiResponse<FinancialStatsDto>.Ok(dto);
    }
}
