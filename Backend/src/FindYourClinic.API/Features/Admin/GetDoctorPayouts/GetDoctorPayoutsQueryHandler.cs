using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetDoctorPayouts;

public class GetDoctorPayoutsQueryHandler : IRequestHandler<GetDoctorPayoutsQuery, ApiResponse<List<DoctorPayoutSummaryDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorPayoutsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<DoctorPayoutSummaryDto>>> Handle(GetDoctorPayoutsQuery request, CancellationToken cancellationToken)
    {
        var wallets = await _dbContext.DoctorWallets
            .AsNoTracking()
            .Include(w => w.DoctorProfile).ThenInclude(d => d.User)
            .Include(w => w.DoctorProfile).ThenInclude(d => d.Specialty)
            .Include(w => w.DoctorProfile).ThenInclude(d => d.PaymentInfo)
            .OrderByDescending(w => w.PendingBalance)
            .ToListAsync(cancellationToken);

        var doctorProfileIds = wallets.Select(w => w.DoctorProfileId).ToList();

        var paidCounts = await _dbContext.Transactions
            .AsNoTracking()
            .Where(t => doctorProfileIds.Contains(t.DoctorProfileId) && t.Status == PaymentStatus.Paid)
            .GroupBy(t => t.DoctorProfileId)
            .Select(g => new { DoctorProfileId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.DoctorProfileId, x => x.Count, cancellationToken);

        var result = wallets.Select(w =>
        {
            var info = w.DoctorProfile.PaymentInfo;
            paidCounts.TryGetValue(w.DoctorProfileId, out var count);

            return new DoctorPayoutSummaryDto(
                DoctorProfileId: w.DoctorProfileId,
                DoctorName: $"{w.DoctorProfile.User.FirstName} {w.DoctorProfile.User.LastName}".Trim(),
                ClinicName: w.DoctorProfile.ClinicName ?? string.Empty,
                Specialty: w.DoctorProfile.Specialty?.Name ?? string.Empty,
                TotalEarnings: w.TotalEarnings,
                PendingBalance: w.PendingBalance,
                WithdrawnAmount: w.WithdrawnAmount,
                TotalPaidTransactions: count,
                PayoutMethod: info?.PayoutMethod.ToString(),
                WalletProvider: info?.WalletProvider?.ToString(),
                WalletPhoneNumber: info?.WalletPhoneNumber,
                BankName: info?.BankName,
                AccountHolderName: info?.AccountHolderName,
                AccountNumber: info?.AccountNumber,
                IBAN: info?.IBAN
            );
        }).ToList();

        return ApiResponse<List<DoctorPayoutSummaryDto>>.Ok(result);
    }
}
