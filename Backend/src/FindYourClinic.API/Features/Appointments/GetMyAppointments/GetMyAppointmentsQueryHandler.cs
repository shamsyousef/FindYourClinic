using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Appointments.GetMyAppointments;

public class GetMyAppointmentsQueryHandler : IRequestHandler<GetMyAppointmentsQuery, ApiResponse<List<AppointmentDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetMyAppointmentsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<AppointmentDto>>> Handle(GetMyAppointmentsQuery request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_ACCESS_THIS_ENDPOINT");
        }

        var items = await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.DoctorProfile).ThenInclude(x => x.User)
            .Include(x => x.DoctorProfile).ThenInclude(x => x.Specialty)
            .Where(x => x.PatientId == request.UserId)
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
                $"{x.DoctorProfile.User.FirstName} {x.DoctorProfile.User.LastName}".Trim(),
                x.DoctorProfile.User.ProfileImageUrl,
                x.DoctorProfile.Specialty.Name,
                x.PaymentStatus,
                x.PaymentMethod,
                x.AmountPaid))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<AppointmentDto>>.Ok(items);
    }
}
