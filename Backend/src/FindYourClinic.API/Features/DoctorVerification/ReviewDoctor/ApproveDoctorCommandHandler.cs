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

public class ApproveDoctorCommandHandler : IRequestHandler<ApproveDoctorCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<ApproveDoctorCommandHandler> _logger;

    public ApproveDoctorCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService,
        ILogger<ApproveDoctorCommandHandler> logger)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<Result> Handle(ApproveDoctorCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        if (doctorProfile.Status != DoctorStatus.PendingReview && doctorProfile.Status != DoctorStatus.Rejected)
        {
            throw new BadRequestException("ONLY_PENDING_OR_REJECTED_DOCTORS_APPROVED");
        }

        doctorProfile.Status = DoctorStatus.Approved;
        doctorProfile.User.IsActive = true;
        doctorProfile.ReviewedAt = DateTime.UtcNow;
        doctorProfile.ReviewedByAdminId = request.AdminId;
        doctorProfile.RejectionReason = null;

        await _dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            await _emailService.SendDoctorApprovedEmailAsync(
                doctorProfile.User.Email ?? string.Empty,
                $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send approval email to {UserId}", doctorProfile.UserId);
        }

        try
        {
            await _notificationService.SendToUserAsync(
                doctorProfile.UserId,
                "Account approved",
                "Your doctor profile has been approved. You can now receive appointments.",
                new Dictionary<string, string>
                {
                    ["type"] = NotificationTypes.DoctorApproved,
                    ["referenceId"] = doctorProfile.Id.ToString()
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send approval notification to {UserId}", doctorProfile.UserId);
        }

        return Result.Success("DOCTOR_APPROVED_SUCCESS");
    }
}
