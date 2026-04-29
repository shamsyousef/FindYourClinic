using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.GetPatientRecords;

public class GetPatientRecordsQueryHandler : IRequestHandler<GetPatientRecordsQuery, ApiResponse<List<HealthRecordDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetPatientRecordsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<HealthRecordDto>>> Handle(GetPatientRecordsQuery request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors can view patient records.");
        }

        // Verify the doctor has an appointment relationship with this patient
        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(dp => dp.UserId == request.DoctorUserId, cancellationToken);

        if (doctorProfile is null)
        {
            throw new NotFoundException("Doctor profile not found.");
        }

        var hasRelationship = await _dbContext.Appointments
            .AnyAsync(a => a.DoctorProfileId == doctorProfile.Id && a.PatientId == request.PatientId, cancellationToken);

        if (!hasRelationship)
        {
            throw new ForbiddenException("You can only view records of patients you have appointments with.");
        }

        var query = _dbContext.HealthRecords
            .AsNoTracking()
            .Where(x => x.PatientId == request.PatientId);

        if (request.Type.HasValue)
        {
            query = query.Where(x => x.Type == request.Type.Value);
        }

        var records = await query
            .OrderByDescending(x => x.RecordedAt)
            .Select(x => new HealthRecordDto(x.Id, x.Title, x.Type.ToString(), x.Value, x.Unit, x.RecordedAt, x.Notes))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<HealthRecordDto>>.Ok(records);
    }
}
