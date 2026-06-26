using Ardalis.Result;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class RejectDoctorCommandHandler : IRequestHandler<RejectDoctorCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<RejectDoctorCommandHandler> _logger;

    public RejectDoctorCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService,
        ILogger<RejectDoctorCommandHandler> _logger)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
        this._logger = _logger;
    }

    public async Task<Result> Handle(RejectDoctorCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        if (doctorProfile.Status != DoctorStatus.PendingReview)
        {
            throw new BadRequestException("ONLY_PENDING_DOCTORS_REJECTED");
        }

        doctorProfile.Status = DoctorStatus.Rejected;
        doctorProfile.User.IsActive = false;
        doctorProfile.ReviewedAt = DateTime.UtcNow;
        doctorProfile.ReviewedByAdminId = request.AdminId;
        doctorProfile.RejectionReason = request.Reason;

        await _dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            await _emailService.SendDoctorRejectedEmailAsync(
                doctorProfile.User.Email ?? string.Empty,
                $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim(),
                request.Reason);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send rejection email to {UserId}", doctorProfile.UserId);
        }

        try
        {
            await _notificationService.SendToUserAsync(
                doctorProfile.UserId,
                "Account review result",
                "Your doctor profile was rejected. Please check the rejection reason and resubmit.",
                new Dictionary<string, string>
                {
                    ["type"] = NotificationTypes.DoctorRejected,
                    ["referenceId"] = doctorProfile.Id.ToString()
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send rejection notification to {UserId}", doctorProfile.UserId);
        }

        return Result.Success("DOCTOR_REJECTED_SUCCESS");
    }
}
