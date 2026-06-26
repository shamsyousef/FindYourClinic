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
            throw new ForbiddenException("ONLY_DOCTORS_CAN_CONFIRM_APPOINTMENTS");
        }

        var appointment = await _dbContext.Appointments
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("APPOINTMENT_NOT_FOUND");

        if (appointment.DoctorProfile.UserId != request.UserId)
        {
            throw new ForbiddenException("FORBIDDEN_TO_CONFIRM_APPOINTMENT");
        }

        if (appointment.Status != AppointmentStatus.Scheduled && appointment.Status != AppointmentStatus.PendingPayment)
        {
            throw new BadRequestException("ONLY_SCHEDULED_OR_PENDING_PAYMENT_APPOINTMENTS_CAN_BE_CONFIRMED");
        }

        // Doctor approval transitions both flows directly to Confirmed:
        //   - Online (Scheduled) → Confirmed
        //   - Cash (PendingPayment) → Confirmed (single approval step; payment
        //     is collected later via MarkAsPaid).
        appointment.Status = AppointmentStatus.Confirmed;
        await _dbContext.SaveChangesAsync(cancellationToken);

        await _notificationService.SendToUserAsync(
            appointment.PatientId,
            "APPOINTMENT_CONFIRMED",
            "APPOINTMENT_CONFIRMED_MESSAGE",
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.AppointmentConfirmed,
                ["referenceId"] = appointment.Id.ToString()
            },
            cancellationToken);

        return ApiResponse<object>.Ok(null, "APPOINTMENT_CONFIRMED");
    }
}
