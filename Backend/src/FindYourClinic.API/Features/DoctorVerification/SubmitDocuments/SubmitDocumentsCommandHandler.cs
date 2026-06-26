using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;

public class SubmitDocumentsCommandHandler : IRequestHandler<SubmitDocumentsCommand, Result<List<UploadedDoctorDocumentDto>>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly ICloudinaryService _cloudinaryService;

    public SubmitDocumentsCommandHandler(ApplicationDbContext dbContext, ICloudinaryService cloudinaryService)
    {
        _dbContext = dbContext;
        _cloudinaryService = cloudinaryService;
    }

    public async Task<Result<List<UploadedDoctorDocumentDto>>> Handle(SubmitDocumentsCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorUserId, cancellationToken);

        if (doctorProfile is null || doctorProfile.User.Role != UserRole.Doctor)
        {
            throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");
        }

        var uploaded = new List<UploadedDoctorDocumentDto>();
        for (var i = 0; i < request.Files.Count; i++)
        {
            var file = request.Files[i];
            var documentType = request.DocumentTypes[i];
            var folder = $"clinic/doctor-documents/{request.DoctorUserId}";
            var result = await _cloudinaryService.UploadFileAsync(file, folder);

            var existingOfType = await _dbContext.DoctorDocuments
                .Where(x => x.DoctorProfileId == doctorProfile.Id && x.DocumentType == documentType)
                .ToListAsync(cancellationToken);
            if (existingOfType.Count > 0)
            {
                _dbContext.DoctorDocuments.RemoveRange(existingOfType);
            }

            _dbContext.DoctorDocuments.Add(new Domain.Entities.DoctorDocument
            {
                DoctorProfileId = doctorProfile.Id,
                DocumentType = documentType,
                FileUrl = result.Url,
                CloudinaryPublicId = result.PublicId,
                UploadedAt = DateTime.UtcNow
            });

            uploaded.Add(new UploadedDoctorDocumentDto
            {
                DocumentType = documentType,
                Url = result.Url
            });
        }

        if (doctorProfile.Status == DoctorStatus.Rejected)
        {
            doctorProfile.Status = DoctorStatus.PendingReview;
            doctorProfile.RejectionReason = null;
            doctorProfile.ReviewedAt = null;
            doctorProfile.ReviewedByAdminId = null;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        return Result.Success(uploaded, "DOCUMENTS_SUBMITTED_SUCCESS");
    }
}
