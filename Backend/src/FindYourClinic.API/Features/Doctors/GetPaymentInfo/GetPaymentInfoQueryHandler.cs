using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetPaymentInfo;

public class GetPaymentInfoQueryHandler : IRequestHandler<GetPaymentInfoQuery, ApiResponse<DoctorPaymentInfoDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetPaymentInfoQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<DoctorPaymentInfoDto>> Handle(GetPaymentInfoQuery request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("Only doctors can access payment info.");

        var profile = await _dbContext.DoctorProfiles
            .Include(x => x.PaymentInfo)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("Doctor profile not found.");

        if (profile.PaymentInfo is null)
            return ApiResponse<DoctorPaymentInfoDto>.Ok(null, "No payment info saved yet.");

        var dto = new DoctorPaymentInfoDto(
            profile.PaymentInfo.PayoutMethod.ToString(),
            profile.PaymentInfo.WalletProvider?.ToString(),
            profile.PaymentInfo.WalletPhoneNumber,
            profile.PaymentInfo.BankName,
            profile.PaymentInfo.AccountHolderName,
            profile.PaymentInfo.AccountNumber,
            profile.PaymentInfo.IBAN);

        return ApiResponse<DoctorPaymentInfoDto>.Ok(dto, "Payment info retrieved.");
    }
}
