using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.GetDoctorPayouts;

public record GetDoctorPayoutsQuery() : IRequest<ApiResponse<List<DoctorPayoutSummaryDto>>>;

public record DoctorPayoutSummaryDto(
    Guid DoctorProfileId,
    string DoctorName,
    string ClinicName,
    string Specialty,
    decimal TotalEarnings,
    decimal PendingBalance,
    decimal WithdrawnAmount,
    int TotalPaidTransactions,
    string? PayoutMethod,
    string? WalletProvider,
    string? WalletPhoneNumber,
    string? BankName,
    string? AccountHolderName,
    string? AccountNumber,
    string? IBAN
);
