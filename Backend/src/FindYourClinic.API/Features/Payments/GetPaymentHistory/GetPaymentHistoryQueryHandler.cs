using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Controllers;

public class GetPaymentHistoryQueryHandler : IRequestHandler<GetPaymentHistoryQuery, ApiResponse<List<TransactionDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetPaymentHistoryQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<TransactionDto>>> Handle(GetPaymentHistoryQuery request, CancellationToken cancellationToken)
    {
        IQueryable<Domain.Entities.Transaction> query;

        if (request.Role == UserRole.Doctor)
        {
            var doctorProfileId = await _dbContext.DoctorProfiles
                .AsNoTracking()
                .Where(x => x.UserId == request.UserId)
                .Select(x => x.Id)
                .FirstOrDefaultAsync(cancellationToken);

            query = _dbContext.Transactions
                .AsNoTracking()
                .Where(x => x.DoctorProfileId == doctorProfileId);
        }
        else
        {
            query = _dbContext.Transactions
                .AsNoTracking()
                .Where(x => x.PatientId == request.UserId);
        }

        var transactions = await query
            .Include(x => x.Patient)
            .Include(x => x.DoctorProfile).ThenInclude(d => d.User)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new TransactionDto(
                x.Id,
                x.AppointmentId,
                x.Amount,
                x.PlatformFee,
                x.DoctorEarnings,
                x.PaymentMethod.ToString(),
                x.Status.ToString(),
                x.CreatedAt,
                x.CompletedAt,
                $"{x.DoctorProfile.User.FirstName} {x.DoctorProfile.User.LastName}".Trim(),
                $"{x.Patient.FirstName} {x.Patient.LastName}".Trim()))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<TransactionDto>>.Ok(transactions);
    }
}
