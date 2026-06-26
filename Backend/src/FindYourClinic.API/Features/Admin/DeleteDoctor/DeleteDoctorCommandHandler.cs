using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Features.Admin.DeleteDoctor;

public class DeleteDoctorCommandHandler : IRequestHandler<DeleteDoctorCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<DeleteDoctorCommandHandler> _logger;

    public DeleteDoctorCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService,
        ILogger<DeleteDoctorCommandHandler> logger)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(DeleteDoctorCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_NOT_FOUND");

        var user = doctorProfile.User;

        // Find upcoming appointments to notify patients
        var upcomingAppointments = await _dbContext.Appointments
            .Where(a => a.DoctorProfileId == doctorProfile.Id 
                     && a.Status == AppointmentStatus.Scheduled 
                     && a.ScheduledAt > DateTime.UtcNow)
            .ToListAsync(cancellationToken);

        foreach (var appointment in upcomingAppointments)
        {
            try
            {
                await _notificationService.SendToUserAsync(
                    appointment.PatientId,
                    "Appointment Cancelled",
                    "Your scheduled doctor broke the app policy and their profile was deleted. Your appointment has been cancelled.",
                    new Dictionary<string, string>
                    {
                        ["type"] = "AppointmentCancelled",
                        ["referenceId"] = appointment.Id.ToString()
                    },
                    cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send cancellation notification to PatientId {PatientId} for appointment {AppointmentId}", appointment.PatientId, appointment.Id);
            }
        }

        // Send deletion email to the doctor
        try
        {
            await _emailService.SendDoctorDeletedEmailAsync(
                user.Email ?? string.Empty,
                $"{user.FirstName} {user.LastName}".Trim(),
                request.Reason);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send deletion email to {UserId}", user.Id);
        }

        // Delete the user from database
        // Due to cascade delete settings, this should remove the profile, appointments, etc.
        _dbContext.Users.Remove(user);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<object>.Ok(null, "DOCTOR_ACCOUNT_DELETED_SUCCESS");
    }
}
