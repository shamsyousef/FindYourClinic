using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.GetMyRecords;

public class GetMyHealthRecordsQueryHandler : IRequestHandler<GetMyHealthRecordsQuery, ApiResponse<List<HealthRecordDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetMyHealthRecordsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<HealthRecordDto>>> Handle(GetMyHealthRecordsQuery request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        var records = await _dbContext.HealthRecords
            .AsNoTracking()
            .Where(x => x.PatientId == request.UserId)
            .OrderByDescending(x => x.RecordedAt)
            .Select(x => new HealthRecordDto(x.Id, x.Title, x.Type.ToString(), x.Value, x.RecordedAt, x.Notes))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<HealthRecordDto>>.Ok(records);
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access health records.");
        }
    }
}
