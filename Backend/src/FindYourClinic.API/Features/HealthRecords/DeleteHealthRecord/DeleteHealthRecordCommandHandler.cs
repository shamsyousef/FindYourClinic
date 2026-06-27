using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.DeleteHealthRecord;

public class DeleteHealthRecordCommandHandler : IRequestHandler<DeleteHealthRecordCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly ICloudinaryService _cloudinaryService;

    public DeleteHealthRecordCommandHandler(ApplicationDbContext dbContext, ICloudinaryService cloudinaryService)
    {
        _dbContext = dbContext;
        _cloudinaryService = cloudinaryService;
    }

    public async Task<ApiResponse<object>> Handle(DeleteHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        var record = await _dbContext.HealthRecords.FirstOrDefaultAsync(x => x.Id == request.RecordId && x.PatientId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("Health record not found.");

        if (!string.IsNullOrEmpty(record.CloudinaryPublicId))
        {
            try
            {
                await _cloudinaryService.DeleteFileAsync(record.CloudinaryPublicId);
            }
            catch (Exception)
            {
                // Log warning/error or ignore to not block database deletion if Cloudinary fails
                throw new CloudinaryException("Error deleting health record from Cloudinary.");
            }
        }

        _dbContext.HealthRecords.Remove(record);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "Health record deleted.");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access health records.");
        }
    }
}
