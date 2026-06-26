using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.GetFinancialStats;

public record GetFinancialStatsQuery() : IRequest<ApiResponse<FinancialStatsDto>>;

public record FinancialStatsDto(
    decimal TotalRevenue,
    decimal TotalVolume,
    int TotalTransactions,
    int PaidTransactions,
    decimal PendingPayouts,
    decimal TotalWithdrawn
);
