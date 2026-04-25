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
            .Select(x => new HealthRecordDto(x.Id, x.Title, x.Type.ToString(), x.Value, x.RecordedAt, x.Notes))
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("Health record not found.");

        return ApiResponse<HealthRecordDto>.Ok(record);
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access health records.");
        }
    }
}
