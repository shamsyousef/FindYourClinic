using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Features.Admin.ToggleDoctorActive;

public class ToggleDoctorActiveCommandHandler : IRequestHandler<ToggleDoctorActiveCommand, ApiResponse<ToggleDoctorActiveResult>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<ToggleDoctorActiveCommandHandler> _logger;

    public ToggleDoctorActiveCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService,
        ILogger<ToggleDoctorActiveCommandHandler> logger)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<ApiResponse<ToggleDoctorActiveResult>> Handle(ToggleDoctorActiveCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_NOT_FOUND");

        doctorProfile.User.IsActive = !doctorProfile.User.IsActive;
        var isNowActive = doctorProfile.User.IsActive;
        var doctorName = $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim();
        var doctorEmail = doctorProfile.User.Email ?? string.Empty;

        await _dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            if (isNowActive)
                await _emailService.SendDoctorActivatedEmailAsync(doctorEmail, doctorName);
            else
                await _emailService.SendDoctorDeactivatedEmailAsync(doctorEmail, doctorName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send toggle-active email to doctor {UserId}", doctorProfile.UserId);
        }

        try
        {
            var notifTitle = isNowActive ? "Account activated" : "Account deactivated";
            var notifBody = isNowActive
                ? "Your account has been activated by the administrator. You can now receive appointments."
                : "Your account has been deactivated by the administrator. Please contact support for more information.";
            var notifType = isNowActive ? NotificationTypes.DoctorActivated : NotificationTypes.DoctorDeactivated;

            await _notificationService.SendToUserAsync(
                doctorProfile.UserId,
                notifTitle,
                notifBody,
                new Dictionary<string, string> { ["type"] = notifType },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send toggle-active notification to doctor {UserId}", doctorProfile.UserId);
        }

        return ApiResponse<ToggleDoctorActiveResult>.Ok(new ToggleDoctorActiveResult(isNowActive));
    }
}
