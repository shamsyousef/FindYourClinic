using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetAllTransactions;

public class GetAllTransactionsQueryHandler : IRequestHandler<GetAllTransactionsQuery, ApiResponse<PagedTransactionsResult>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetAllTransactionsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<PagedTransactionsResult>> Handle(GetAllTransactionsQuery request, CancellationToken cancellationToken)
    {
        var query = _dbContext.Transactions
            .AsNoTracking()
            .Include(t => t.DoctorProfile).ThenInclude(d => d.User)
            .Include(t => t.DoctorProfile).ThenInclude(d => d.Specialty)
            .Include(t => t.Patient)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(request.Status) &&
            Enum.TryParse<PaymentStatus>(request.Status, ignoreCase: true, out var parsedStatus))
        {
            query = query.Where(t => t.Status == parsedStatus);
        }

        if (!string.IsNullOrWhiteSpace(request.PaymentMethod) &&
            Enum.TryParse<PaymentMethod>(request.PaymentMethod, ignoreCase: true, out var parsedMethod))
        {
            query = query.Where(t => t.PaymentMethod == parsedMethod);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderByDescending(t => t.CreatedAt)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(t => new AdminTransactionDto(
                t.Id,
                t.AppointmentId,
                $"{t.DoctorProfile.User.FirstName} {t.DoctorProfile.User.LastName}".Trim(),
                t.DoctorProfile.ClinicName ?? string.Empty,
                t.DoctorProfile.Specialty.Name,
                $"{t.Patient.FirstName} {t.Patient.LastName}".Trim(),
                t.Amount,
                t.PlatformFee,
                t.DoctorEarnings,
                t.PaymentMethod.ToString(),
                t.Status.ToString(),
                t.CreatedAt,
                t.CompletedAt
            ))
            .ToListAsync(cancellationToken);

        return ApiResponse<PagedTransactionsResult>.Ok(new PagedTransactionsResult(
            Items: items,
            TotalCount: totalCount,
            Page: request.Page,
            PageSize: request.PageSize
        ));
    }
}
