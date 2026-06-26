
using Ardalis.Result;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class SetDoctorPendingCommandHandler : IRequestHandler<SetDoctorPendingCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;
    private readonly ILogger<SetDoctorPendingCommandHandler> _logger;

    public SetDoctorPendingCommandHandler(
        ApplicationDbContext dbContext,
        INotificationService notificationService,
        ILogger<SetDoctorPendingCommandHandler> logger)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(SetDoctorPendingCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        if (doctorProfile.Status == DoctorStatus.PendingReview)
        {
            throw new BadRequestException("DOCTOR_ALREADY_PENDING_REVIEW");
        }

        doctorProfile.Status = DoctorStatus.PendingReview;
        doctorProfile.User.IsActive = false;
        doctorProfile.ReviewedAt = null;
        doctorProfile.ReviewedByAdminId = null;
        doctorProfile.RejectionReason = null;

        await _dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            await _notificationService.SendToUserAsync(
                doctorProfile.UserId,
                "Account under review",
                "Your doctor profile has been moved back to pending review status.",
                new Dictionary<string, string>
                {
                    ["type"] = "DoctorPendingReview",
                    ["referenceId"] = doctorProfile.Id.ToString()
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send pending review notification to {UserId}", doctorProfile.UserId);
        }

        return ApiResponse<object>.Ok(

            null,
            "DOCTOR_SET_PENDING_SUCCESS"
            );
    }
}
