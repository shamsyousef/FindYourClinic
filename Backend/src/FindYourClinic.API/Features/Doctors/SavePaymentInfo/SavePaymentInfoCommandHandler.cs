using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.SavePaymentInfo;

public class SavePaymentInfoCommandHandler : IRequestHandler<SavePaymentInfoCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;

    public SavePaymentInfoCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(SavePaymentInfoCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("Only doctors can update payment info.");

        var profile = await _dbContext.DoctorProfiles
            .Include(x => x.PaymentInfo)
            .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("Doctor profile not found.");

        if (profile.PaymentInfo is null)
        {
            profile.PaymentInfo = new DoctorPaymentInfo
            {
                DoctorProfileId = profile.Id
            };
            _dbContext.DoctorPaymentInfos.Add(profile.PaymentInfo);
        }

        profile.PaymentInfo.PayoutMethod = request.PayoutMethod;
        profile.PaymentInfo.WalletProvider = request.WalletProvider;
        profile.PaymentInfo.WalletPhoneNumber = request.WalletPhoneNumber?.Trim();
        profile.PaymentInfo.BankName = request.BankName?.Trim();
        profile.PaymentInfo.AccountHolderName = request.AccountHolderName?.Trim();
        profile.PaymentInfo.AccountNumber = request.AccountNumber?.Trim();
        profile.PaymentInfo.IBAN = request.IBAN?.Trim();

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<object>.Ok(null, "Payment info saved.");
    }
}
