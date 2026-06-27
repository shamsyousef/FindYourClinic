using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.GetHealthSummary;

public class GetHealthSummaryQueryHandler : IRequestHandler<GetHealthSummaryQuery, ApiResponse<HealthSummaryDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetHealthSummaryQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<HealthSummaryDto>> Handle(GetHealthSummaryQuery request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        var records = await _dbContext.HealthRecords
            .AsNoTracking()
            .Where(x => x.PatientId == request.UserId)
            .OrderByDescending(x => x.RecordedAt)
            .ToListAsync(cancellationToken);

        var summary = new HealthSummaryDto(
            records.Count,
            MapVital(records, HealthRecordType.BloodPressure),
            MapVital(records, HealthRecordType.HeartRate),
            MapVital(records, HealthRecordType.BloodSugar),
            MapVital(records, HealthRecordType.Temperature),
            MapVital(records, HealthRecordType.Weight),
            MapVital(records, HealthRecordType.SpO2));

        return ApiResponse<HealthSummaryDto>.Ok(summary);
    }

    private static VitalDto? MapVital(List<Domain.Entities.HealthRecord> records, HealthRecordType type)
    {
        var latest = records.FirstOrDefault(x => x.Type == type);
        if (latest?.Value is null) return null;
        return new VitalDto(latest.Value, latest.Unit, latest.RecordedAt);
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access health records.");
        }
    }
}
