using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.CompleteAppointment;

public class CompleteAppointmentCommandHandler : IRequestHandler<CompleteAppointmentCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public CompleteAppointmentCommandHandler(ApplicationDbContext dbContext, INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<ApiResponse<object>> Handle(CompleteAppointmentCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("ONLY_DOCTORS_CAN_COMPLETE_APPOINTMENTS");
        }

        var appointment = await _dbContext.Appointments
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("APPOINTMENT_NOT_FOUND");

        if (appointment.DoctorProfile.UserId != request.UserId)
        {
            throw new ForbiddenException("FORBIDDEN_TO_COMPLETE_APPOINTMENT");
        }

        if (appointment.Status != AppointmentStatus.Confirmed)
        {
            throw new BadRequestException("ONLY_CONFIRMED_APPOINTMENTS_CAN_BE_COMPLETED");
        }

        appointment.Status = AppointmentStatus.Completed;
        await _dbContext.SaveChangesAsync(cancellationToken);

        await _notificationService.SendToUserAsync(
            appointment.PatientId,
            "APPOINTMENT_COMPLETED",
            "APPOINTMENT_COMPLETED_MESSAGE",
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.AppointmentCompleted,
                ["referenceId"] = appointment.Id.ToString()
            },
            cancellationToken);

        return ApiResponse<object>.Ok(null, "APPOINTMENT_COMPLETED");
    }
}
