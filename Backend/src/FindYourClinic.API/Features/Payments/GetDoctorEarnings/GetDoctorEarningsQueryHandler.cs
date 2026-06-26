using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Controllers;

public class GetDoctorEarningsQueryHandler : IRequestHandler<GetDoctorEarningsQuery, ApiResponse<DoctorEarningsDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorEarningsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<DoctorEarningsDto>> Handle(GetDoctorEarningsQuery request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("ONLY_DOCTORS_CAN_VIEW_EARNINGS");

        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        var wallet = await _dbContext.DoctorWallets
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.DoctorProfileId == doctorProfile.Id, cancellationToken);

        var totalTransactions = await _dbContext.Transactions
            .AsNoTracking()
            .CountAsync(x => x.DoctorProfileId == doctorProfile.Id && x.Status == PaymentStatus.Paid, cancellationToken);

        var dto = new DoctorEarningsDto(
            wallet?.TotalEarnings ?? 0,
            wallet?.PendingBalance ?? 0,
            wallet?.WithdrawnAmount ?? 0,
            totalTransactions);

        return ApiResponse<DoctorEarningsDto>.Ok(dto);
    }
}
