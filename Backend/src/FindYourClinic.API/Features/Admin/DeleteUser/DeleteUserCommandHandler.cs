using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Features.Admin.DeleteUser;

public class DeleteUserCommandHandler : IRequestHandler<DeleteUserCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<DeleteUserCommandHandler> _logger;

    public DeleteUserCommandHandler(
        ApplicationDbContext dbContext,
        IEmailService emailService,
        INotificationService notificationService,
        ILogger<DeleteUserCommandHandler> logger)
    {
        _dbContext = dbContext;
        _emailService = emailService;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(DeleteUserCommand request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == request.UserId, cancellationToken)
            ?? throw new NotFoundException("USER_NOT_FOUND");

        // Prevent admins from deleting other admin accounts
        if (user.Role == UserRole.Admin)
        {
            throw new BadRequestException("CANNOT_DELETE_ADMIN_ACCOUNTS");
        }

        var fullName = $"{user.FirstName} {user.LastName}".Trim();
        var email = user.Email ?? string.Empty;
        var isDoctor = user.Role == UserRole.Doctor;

        // If the user is a doctor, cancel upcoming appointments and notify patients
        if (isDoctor)
        {
            var doctorProfile = await _dbContext.DoctorProfiles
                .FirstOrDefaultAsync(dp => dp.UserId == user.Id, cancellationToken);

            if (doctorProfile != null)
            {
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
                            "Your scheduled doctor's account has been removed. Your appointment has been cancelled.",
                            new Dictionary<string, string>
                            {
                                ["type"] = "AppointmentCancelled",
                                ["referenceId"] = appointment.Id.ToString()
                            },
                            cancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to send cancellation notification to PatientId {PatientId}", appointment.PatientId);
                    }
                }
            }
        }

        // Send deletion email
        try
        {
            if (isDoctor)
            {
                await _emailService.SendDoctorDeletedEmailAsync(email, fullName, request.Reason);
            }
            else
            {
                await _emailService.SendPatientDeletedEmailAsync(email, fullName, request.Reason);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send deletion email to {Email}", email);
        }

        // Delete the user (cascade deletes related data)
        _dbContext.Users.Remove(user);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<object>.Ok(null, "USER_ACCOUNT_DELETED_SUCCESS");
    }
}
