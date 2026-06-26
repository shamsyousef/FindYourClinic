using Ardalis.Result;
using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.UpdateHealthRecord;

public class UpdateHealthRecordCommandHandler : IRequestHandler<UpdateHealthRecordCommand, Result<HealthRecordDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public UpdateHealthRecordCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result<HealthRecordDto>> Handle(UpdateHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new BadRequestException("TITLE_REQUIRED");
        }

        var record = await _dbContext.HealthRecords
            .FirstOrDefaultAsync(x => x.Id == request.RecordId && x.PatientId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("HEALTH_RECORD_NOT_FOUND");

        record.Title = request.Title.Trim();
        record.Type = request.Type;
        record.Value = request.Value?.Trim();
        record.Unit = request.Unit?.Trim();
        record.RecordedAt = request.RecordedAt ?? record.RecordedAt;
        record.Notes = request.Notes?.Trim();

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Result.Success(
            new HealthRecordDto(record.Id, record.Title, record.Type.ToString(), record.Value, record.Unit, record.RecordedAt, record.Notes, record.FileUrl),
            "HEALTH_RECORD_UPDATED_SUCCESS");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_UPDATE_HEALTH_RECORDS");
        }
    }
}
