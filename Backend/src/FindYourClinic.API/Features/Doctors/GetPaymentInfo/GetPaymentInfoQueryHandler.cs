using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetPaymentInfo;

public class GetPaymentInfoQueryHandler : IRequestHandler<GetPaymentInfoQuery, Result<DoctorPaymentInfoDto?>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetPaymentInfoQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result<DoctorPaymentInfoDto?>> Handle(GetPaymentInfoQuery request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("ONLY_DOCTORS_CAN_ACCESS_PAYMENT_INFO");

        var profile = await _dbContext.DoctorProfiles
            .Include(x => x.PaymentInfo)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        if (profile.PaymentInfo is null)
            return Result.Success<DoctorPaymentInfoDto?>(null, "NO_PAYMENT_INFO_SAVED_YET");

        var dto = new DoctorPaymentInfoDto(
            profile.PaymentInfo.PayoutMethod.ToString(),
            profile.PaymentInfo.WalletProvider?.ToString(),
            profile.PaymentInfo.WalletPhoneNumber,
            profile.PaymentInfo.BankName,
            profile.PaymentInfo.AccountHolderName,
            profile.PaymentInfo.AccountNumber,
            profile.PaymentInfo.IBAN);

        return Result.Success<DoctorPaymentInfoDto?>(dto, "PAYMENT_INFO_RETRIEVED_SUCCESS");
    }
}
