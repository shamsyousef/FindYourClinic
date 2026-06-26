using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Persistence;
using FindYourClinic.Infrastructure.Services;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.DeleteHealthRecord;

public class DeleteHealthRecordCommandHandler : IRequestHandler<DeleteHealthRecordCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly ICloudinaryService _cloudinaryService;

    public DeleteHealthRecordCommandHandler(ApplicationDbContext dbContext, ICloudinaryService cloudinaryService)
    {
        _dbContext = dbContext;
        _cloudinaryService = cloudinaryService;
    }

    public async Task<Result> Handle(DeleteHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        var record = await _dbContext.HealthRecords.FirstOrDefaultAsync(x => x.Id == request.RecordId && x.PatientId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("HEALTH_RECORD_NOT_FOUND");

        if (!string.IsNullOrEmpty(record.CloudinaryPublicId))
        {
            try
            {
                await _cloudinaryService.DeleteFileAsync(record.CloudinaryPublicId);
            }
            catch (Exception)
            {
                // Log warning/error or ignore to not block database deletion if Cloudinary fails
                throw new CloudinaryException("ERROR_DELETING_FROM_CLOUDINARY");
            }
        }

        _dbContext.HealthRecords.Remove(record);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return Result.Success("HEALTH_RECORD_DELETED_SUCCESS");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_ACCESS_HEALTH_RECORDS");
        }
    }
}
