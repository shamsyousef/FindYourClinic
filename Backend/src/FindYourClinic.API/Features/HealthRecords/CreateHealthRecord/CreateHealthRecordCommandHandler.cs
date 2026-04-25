using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.CreateHealthRecord;

public class CreateHealthRecordCommandHandler : IRequestHandler<CreateHealthRecordCommand, ApiResponse<HealthRecordDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public CreateHealthRecordCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<HealthRecordDto>> Handle(CreateHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new BadRequestException("Title is required.");
        }

        var entity = new HealthRecord
        {
            PatientId = request.UserId,
            Title = request.Title.Trim(),
            Type = request.Type,
            Value = request.Value?.Trim(),
            RecordedAt = request.RecordedAt ?? DateTime.UtcNow,
            Notes = request.Notes?.Trim()
        };

        _dbContext.HealthRecords.Add(entity);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<HealthRecordDto>.Ok(new HealthRecordDto(entity.Id, entity.Title, entity.Type.ToString(), entity.Value, entity.RecordedAt, entity.Notes), "Health record created.");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access health records.");
        }
    }
}
