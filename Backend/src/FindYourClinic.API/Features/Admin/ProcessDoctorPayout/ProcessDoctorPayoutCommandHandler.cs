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
            return ApiResponse<string>.Fail("Doctor wallet not found.");

        if (wallet.PendingBalance <= 0)
            return ApiResponse<string>.Fail("No pending balance to payout.");

        wallet.WithdrawnAmount += wallet.PendingBalance;
        wallet.PendingBalance = 0;

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<string>.Ok("Payout recorded successfully.");
    }
}
