using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.CancelAppointment;

public class CancelAppointmentCommandHandler : IRequestHandler<CancelAppointmentCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public CancelAppointmentCommandHandler(ApplicationDbContext dbContext, INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<ApiResponse<object>> Handle(CancelAppointmentCommand request, CancellationToken cancellationToken)
    {
        var appointment = await _dbContext.Appointments
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("Appointment not found.");

        if (request.Role == UserRole.Patient && appointment.PatientId != request.UserId)
        {
            throw new ForbiddenException("You cannot cancel this appointment.");
        }

        if (request.Role == UserRole.Doctor && appointment.DoctorProfile.UserId != request.UserId)
        {
            throw new ForbiddenException("You cannot cancel this appointment.");
        }

        if (appointment.Status == AppointmentStatus.Completed)
        {
            throw new BadRequestException("Completed appointments cannot be cancelled.");
        }

        appointment.Status = AppointmentStatus.Cancelled;
        await _dbContext.SaveChangesAsync(cancellationToken);

        Guid targetUserId;
        if (request.Role == UserRole.Patient)
        {
            targetUserId = appointment.DoctorProfile.UserId;
        }
        else if (request.Role == UserRole.Doctor)
        {
            targetUserId = appointment.PatientId;
        }
        else
        {
            throw new ForbiddenException("Only patient or doctor can cancel appointments.");
        }

        await _notificationService.SendToUserAsync(
            targetUserId,
            "Appointment cancelled",
            "An appointment has been cancelled. Please check details in the app.",
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.AppointmentCancelled,
                ["referenceId"] = appointment.Id.ToString()
            },
            cancellationToken);

        return ApiResponse<object>.Ok(null, "Appointment cancelled.");
    }
}
