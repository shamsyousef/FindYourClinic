using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.ProcessDoctorPayout;

public class ProcessDoctorPayoutCommandHandler : IRequestHandler<ProcessDoctorPayoutCommand, ApiResponse<string>>
{
    private readonly ApplicationDbContext _dbContext;

    public ProcessDoctorPayoutCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<string>> Handle(ProcessDoctorPayoutCommand request, CancellationToken cancellationToken)
    {
        var wallet = await _dbContext.DoctorWallets
            .FirstOrDefaultAsync(w => w.DoctorProfileId == request.DoctorProfileId, cancellationToken);

        if (wallet is null)
            return ApiResponse<string>.Fail("DOCTOR_WALLET_NOT_FOUND");

        if (wallet.PendingBalance <= 0)
            return ApiResponse<string>.Fail("NO_PENDING_BALANCE_TO_PAYOUT");

        wallet.WithdrawnAmount += wallet.PendingBalance;
        wallet.PendingBalance = 0;

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<string>.Ok("PAYOUT_RECORDED_SUCCESS");
    }
}
