using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class ApproveDoctorCommandHandler : IRequestHandler<ApproveDoctorCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;

    public ApproveDoctorCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
    }

    public async Task<ApiResponse<object>> Handle(ApproveDoctorCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("Doctor not found.");

        if (doctorProfile.Status != DoctorStatus.PendingReview)
        {
            throw new BadRequestException("Only pending doctors can be approved.");
        }

        doctorProfile.Status = DoctorStatus.Approved;
        doctorProfile.User.IsActive = true;
        doctorProfile.ReviewedAt = DateTime.UtcNow;
        doctorProfile.ReviewedByAdminId = request.AdminId;
        doctorProfile.RejectionReason = null;

        await _dbContext.SaveChangesAsync(cancellationToken);

        await _emailService.SendDoctorApprovedEmailAsync(
            doctorProfile.User.Email ?? string.Empty,
            $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim());

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

        return ApiResponse<object>.Ok(null, "Doctor approved successfully.");
    }
}
