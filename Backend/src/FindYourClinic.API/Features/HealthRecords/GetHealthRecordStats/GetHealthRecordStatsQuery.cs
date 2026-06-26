using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.GetHealthRecordStats;

public class GetHealthRecordStatsQuery : IRequest<ApiResponse<HealthRecordStatsDto>>
{
}

public sealed record HealthRecordStatsDto(
    int TotalRecords,
    int PatientsWithRecords,
    int RecordsThisMonth,
    Dictionary<string, int> RecordsByType);
