using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.UpdateHealthRecord;

public class UpdateHealthRecordCommandHandler : IRequestHandler<UpdateHealthRecordCommand, ApiResponse<HealthRecordDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public UpdateHealthRecordCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<HealthRecordDto>> Handle(UpdateHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new BadRequestException("Title is required.");
        }

        var record = await _dbContext.HealthRecords
            .FirstOrDefaultAsync(x => x.Id == request.RecordId && x.PatientId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("Health record not found.");

        record.Title = request.Title.Trim();
        record.Type = request.Type;
        record.Value = request.Value?.Trim();
        record.Unit = request.Unit?.Trim();
        record.RecordedAt = request.RecordedAt ?? record.RecordedAt;
        record.Notes = request.Notes?.Trim();

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<HealthRecordDto>.Ok(
            new HealthRecordDto(record.Id, record.Title, record.Type.ToString(), record.Value, record.Unit, record.RecordedAt, record.Notes),
            "Health record updated.");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can update health records.");
        }
    }
}
