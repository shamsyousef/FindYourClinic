using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.BookAppointment;

public class BookAppointmentCommandHandler
    : IRequestHandler<BookAppointmentCommand, ApiResponse<AppointmentDto>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public BookAppointmentCommandHandler(
        ApplicationDbContext dbContext,
        INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<ApiResponse<AppointmentDto>> Handle(
        BookAppointmentCommand request,
        CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_BOOK_APPOINTMENTS");
        }

        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .Include(x => x.Specialty)
            .FirstOrDefaultAsync(
                x => x.Id == request.DoctorProfileId &&
                     x.Status == DoctorStatus.Approved &&
                     x.User.IsActive,
                cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        if (request.ScheduledAt <= DateTime.UtcNow)
        {
            throw new BadRequestException("APPOINTMENT_MUST_BE_IN_THE_FUTURE");
        }

        if (request.ScheduledAt.Second != 0 ||
            request.ScheduledAt.Millisecond != 0 ||
            request.ScheduledAt.Minute % 30 != 0)
        {
            throw new BadRequestException("APPOINTMENTS_MUST_BE_ON_30_MINUTE_SLOTS");
        }

        var isInsideAvailabilityWindow = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .AnyAsync(x =>
                x.DoctorProfileId == request.DoctorProfileId &&
                x.IsActive &&
                x.DayOfWeek == request.ScheduledAt.DayOfWeek &&
                x.StartTime <= request.ScheduledAt.TimeOfDay &&
                request.ScheduledAt.TimeOfDay < x.EndTime,
                cancellationToken);

        if (!isInsideAvailabilityWindow)
        {
            throw new BadRequestException("SELECTED_TIME_OUTSIDE_AVAILABILITY");
        }

        var overlapping = await _dbContext.Appointments.AnyAsync(
            x => x.DoctorProfileId == request.DoctorProfileId &&
                 x.ScheduledAt == request.ScheduledAt &&
                 x.Status != AppointmentStatus.Cancelled,
            cancellationToken);

        if (overlapping)
        {
            throw new BadRequestException("SLOT_ALREADY_BOOKED");
        }

        var appointment = new Appointment
        {
            PatientId = request.UserId,
            DoctorProfileId = request.DoctorProfileId,
            ScheduledAt = request.ScheduledAt,
            LocationName = string.IsNullOrWhiteSpace(request.LocationName)
                ? doctorProfile.ClinicName
                : request.LocationName.Trim(),
            Status = AppointmentStatus.Scheduled
        };

        _dbContext.Appointments.Add(appointment);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // =========================
        // NOTIFICATION (FIXED)
        // =========================
        await _notificationService.SendToUserAsync(
            doctorProfile.UserId,
            "NEW_APPOINTMENT_BOOKED",
            "NEW_APPOINTMENT_BOOKED_MESSAGE",
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.AppointmentBooked,
                ["referenceId"] = appointment.Id.ToString()
            },
            cancellationToken);

        var dto = new AppointmentDto(
            appointment.Id,
            appointment.PatientId,
            appointment.DoctorProfileId,
            doctorProfile.UserId,
            appointment.ScheduledAt,
            appointment.LocationName,
            appointment.Status.ToString(),
            appointment.CreatedAt,
            $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim(),
            doctorProfile.User.ProfileImageUrl,
            doctorProfile.Specialty?.Name,
            appointment.PaymentStatus.ToString(),
            appointment.PaymentMethod?.ToString(),
            appointment.AmountPaid);

        return ApiResponse<AppointmentDto>.Ok(
            dto,
            "APPOINTMENT_BOOKED_SUCCESS"
        );
    }
}