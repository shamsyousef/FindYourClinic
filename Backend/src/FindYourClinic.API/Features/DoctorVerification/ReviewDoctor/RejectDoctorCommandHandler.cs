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

public class RejectDoctorCommandHandler : IRequestHandler<RejectDoctorCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;

    public RejectDoctorCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
    }

    public async Task<ApiResponse<object>> Handle(RejectDoctorCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("Doctor not found.");

        if (doctorProfile.Status != DoctorStatus.PendingReview)
        {
            throw new BadRequestException("Only pending doctors can be rejected.");
        }

        doctorProfile.Status = DoctorStatus.Rejected;
        doctorProfile.User.IsActive = false;
        doctorProfile.ReviewedAt = DateTime.UtcNow;
        doctorProfile.ReviewedByAdminId = request.AdminId;
        doctorProfile.RejectionReason = request.Reason;

        await _dbContext.SaveChangesAsync(cancellationToken);

        await _emailService.SendDoctorRejectedEmailAsync(
            doctorProfile.User.Email ?? string.Empty,
            $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim(),
            request.Reason);

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

        return ApiResponse<object>.Ok(null, "Doctor rejected successfully.");
    }
}
