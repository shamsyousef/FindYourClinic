using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.GetHealthRecordById;

public class GetHealthRecordByIdQueryHandler : IRequestHandler<GetHealthRecordByIdQuery, ApiResponse<HealthRecordDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetHealthRecordByIdQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<HealthRecordDto>> Handle(GetHealthRecordByIdQuery request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        var record = await _dbContext.HealthRecords
            .AsNoTracking()
            .Where(x => x.Id == request.RecordId && x.PatientId == request.UserId)
            .Select(x => new HealthRecordDto(x.Id, x.Title, x.Type.ToString(), x.Value, x.Unit, x.RecordedAt, x.Notes,x.FileUrl))
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("HEALTH_RECORD_NOT_FOUND");

        return ApiResponse<HealthRecordDto>.Ok(record);
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_ACCESS_HEALTH_RECORDS");
        }
    }
}
