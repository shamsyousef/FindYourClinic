using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.GetDoctorAppointments;

public class GetDoctorAppointmentsQueryHandler : IRequestHandler<GetDoctorAppointmentsQuery, ApiResponse<List<AppointmentDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorAppointmentsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<AppointmentDto>>> Handle(GetDoctorAppointmentsQuery request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("ONLY_DOCTORS_CAN_ACCESS_THIS_ENDPOINT");
        }

        var doctorProfileId = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.UserId == request.UserId)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        var items = await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Patient)
            .Include(x => x.DoctorProfile).ThenInclude(x => x.Specialty)
            .Where(x => x.DoctorProfileId == doctorProfileId)
            .OrderBy(x => x.ScheduledAt)
            .Select(x => AppointmentMappings.ToDtoProjection(
                x.Id,
                x.PatientId,
                x.DoctorProfileId,
                x.DoctorProfile.UserId,
                x.ScheduledAt,
                x.LocationName,
                x.Status,
                x.CreatedAt,
                $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                x.Patient.ProfileImageUrl,
                x.DoctorProfile.Specialty.Name,
                x.PaymentStatus,
                x.PaymentMethod,
                x.AmountPaid))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<AppointmentDto>>.Ok(items);
    }
}
