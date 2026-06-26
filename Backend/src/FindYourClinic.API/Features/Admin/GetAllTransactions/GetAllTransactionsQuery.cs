using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.GetAllTransactions;

public record GetAllTransactionsQuery(
    int Page,
    int PageSize,
    string? Status,
    string? PaymentMethod
) : IRequest<ApiResponse<PagedTransactionsResult>>;

public record AdminTransactionDto(
    Guid Id,
    Guid AppointmentId,
    string DoctorName,
    string ClinicName,
    string Specialty,
    string PatientName,
    decimal ConsultationFee,
    decimal PlatformFee,
    decimal DoctorEarnings,
    string PaymentMethod,
    string Status,
    DateTime CreatedAt,
    DateTime? CompletedAt
);

public record PagedTransactionsResult(
    List<AdminTransactionDto> Items,
    int TotalCount,
    int Page,
    int PageSize
);
