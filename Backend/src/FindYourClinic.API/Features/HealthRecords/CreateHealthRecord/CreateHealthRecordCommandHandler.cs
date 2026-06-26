using Ardalis.Result;
using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.CreateHealthRecord;

public class CreateHealthRecordCommandHandler : IRequestHandler<CreateHealthRecordCommand, Result<HealthRecordDto>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly ICloudinaryService _cloudinaryService;

    public CreateHealthRecordCommandHandler(ApplicationDbContext dbContext, ICloudinaryService cloudinaryService)
    {
        _dbContext = dbContext;
        _cloudinaryService = cloudinaryService;
    }

    public async Task<Result<HealthRecordDto>> Handle(CreateHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new BadRequestException("TITLE_REQUIRED");
        }

        string? fileUrl = null;
        string? cloudinaryPublicId = null;

        if (request.Attachment is not null)
        {
            var folder = $"clinic/health-records/{request.UserId}";
            var isImage = request.Attachment.ContentType.ToLower().StartsWith("image/");
            var uploadResult = isImage
                ? await _cloudinaryService.UploadImageAsync(request.Attachment, folder)
                : await _cloudinaryService.UploadFileAsync(request.Attachment, folder);

            fileUrl = uploadResult.Url;
            cloudinaryPublicId = uploadResult.PublicId;
        }

        var entity = new HealthRecord
        {
            PatientId = request.UserId,
            Title = request.Title.Trim(),
            Type = request.Type,
            Value = request.Value?.Trim(),
            Unit = request.Unit?.Trim(),
            RecordedAt = request.RecordedAt ?? DateTime.UtcNow,
            Notes = request.Notes?.Trim(),
            FileUrl = fileUrl,
            CloudinaryPublicId = cloudinaryPublicId
        };

        _dbContext.HealthRecords.Add(entity);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return Result.Success(
            new HealthRecordDto(entity.Id, entity.Title, entity.Type.ToString(), entity.Value, entity.Unit, entity.RecordedAt, entity.Notes, entity.FileUrl),
            "HEALTH_RECORD_CREATED_SUCCESS");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_ACCESS_HEALTH_RECORDS");
        }
    }
}