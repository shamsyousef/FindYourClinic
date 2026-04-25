using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.ConfirmAppointment;

public class ConfirmAppointmentCommandHandler : IRequestHandler<ConfirmAppointmentCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public ConfirmAppointmentCommandHandler(ApplicationDbContext dbContext, INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<ApiResponse<object>> Handle(ConfirmAppointmentCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors can confirm appointments.");
        }

        var appointment = await _dbContext.Appointments
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("Appointment not found.");

        if (appointment.DoctorProfile.UserId != request.UserId)
        {
            throw new ForbiddenException("You cannot confirm this appointment.");
        }

        if (appointment.Status != AppointmentStatus.Scheduled)
        {
            throw new BadRequestException("Only scheduled appointments can be confirmed.");
        }

        appointment.Status = AppointmentStatus.Confirmed;
        await _dbContext.SaveChangesAsync(cancellationToken);

        await _notificationService.SendToUserAsync(
            appointment.PatientId,
            "Appointment confirmed",
            $"Your appointment is confirmed for {appointment.ScheduledAt:MMM dd 'at' hh:mm tt}.",
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.AppointmentConfirmed,
                ["referenceId"] = appointment.Id.ToString()
            },
            cancellationToken);

        return ApiResponse<object>.Ok(null, "Appointment confirmed.");
    }
}
