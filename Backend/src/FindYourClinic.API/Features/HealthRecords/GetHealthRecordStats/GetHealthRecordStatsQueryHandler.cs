using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.GetHealthRecordStats;

public class GetHealthRecordStatsQueryHandler : IRequestHandler<GetHealthRecordStatsQuery, ApiResponse<HealthRecordStatsDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetHealthRecordStatsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<HealthRecordStatsDto>> Handle(GetHealthRecordStatsQuery request, CancellationToken cancellationToken)
    {
        var records = _dbContext.HealthRecords.AsNoTracking();

        var totalRecords = await records.CountAsync(cancellationToken);

        var patientsWithRecords = await records
            .Select(x => x.PatientId)
            .Distinct()
            .CountAsync(cancellationToken);

        var startOfMonth = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var recordsThisMonth = await records
            .Where(x => x.CreatedAt >= startOfMonth)
            .CountAsync(cancellationToken);

        var recordsByType = await records
            .GroupBy(x => x.Type)
            .Select(g => new { Type = g.Key.ToString(), Count = g.Count() })
            .ToDictionaryAsync(x => x.Type, x => x.Count, cancellationToken);

        return ApiResponse<HealthRecordStatsDto>.Ok(
            new HealthRecordStatsDto(totalRecords, patientsWithRecords, recordsThisMonth, recordsByType));
    }
}
