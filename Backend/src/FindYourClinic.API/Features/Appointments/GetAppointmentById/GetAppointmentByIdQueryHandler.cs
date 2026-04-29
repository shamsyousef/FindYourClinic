using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.GetAppointmentById;

public class GetAppointmentByIdQueryHandler : IRequestHandler<GetAppointmentByIdQuery, ApiResponse<AppointmentDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetAppointmentByIdQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<AppointmentDto>> Handle(GetAppointmentByIdQuery request, CancellationToken cancellationToken)
    {
        var appointment = await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Patient)
            .Include(x => x.DoctorProfile).ThenInclude(x => x.User)
            .Include(x => x.DoctorProfile).ThenInclude(x => x.Specialty)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("Appointment not found.");

        // Authorization: only the patient or doctor on this appointment can view it
        if (request.Role == UserRole.Patient && appointment.PatientId != request.UserId)
        {
            throw new ForbiddenException("You cannot view this appointment.");
        }

        if (request.Role == UserRole.Doctor && appointment.DoctorProfile.UserId != request.UserId)
        {
            throw new ForbiddenException("You cannot view this appointment.");
        }

        // Map related person based on caller role
        string relatedPersonName;
        string? relatedPersonImageUrl;

        if (request.Role == UserRole.Patient)
        {
            relatedPersonName = $"{appointment.DoctorProfile.User.FirstName} {appointment.DoctorProfile.User.LastName}".Trim();
            relatedPersonImageUrl = appointment.DoctorProfile.User.ProfileImageUrl;
        }
        else
        {
            relatedPersonName = $"{appointment.Patient.FirstName} {appointment.Patient.LastName}".Trim();
            relatedPersonImageUrl = appointment.Patient.ProfileImageUrl;
        }

        var dto = new AppointmentDto(
            appointment.Id,
            appointment.PatientId,
            appointment.DoctorProfileId,
            appointment.DoctorProfile.UserId,
            appointment.ScheduledAt,
            appointment.LocationName,
            appointment.Status.ToString(),
            appointment.CreatedAt,
            relatedPersonName,
            relatedPersonImageUrl,
            appointment.DoctorProfile.Specialty?.Name);

        return ApiResponse<AppointmentDto>.Ok(dto);
    }
}
