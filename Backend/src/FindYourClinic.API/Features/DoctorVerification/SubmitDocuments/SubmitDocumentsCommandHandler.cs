using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;

public class SubmitDocumentsCommandHandler : IRequestHandler<SubmitDocumentsCommand, ApiResponse<List<UploadedDoctorDocumentDto>>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly ICloudinaryService _cloudinaryService;

    public SubmitDocumentsCommandHandler(ApplicationDbContext dbContext, ICloudinaryService cloudinaryService)
    {
        _dbContext = dbContext;
        _cloudinaryService = cloudinaryService;
    }

    public async Task<ApiResponse<List<UploadedDoctorDocumentDto>>> Handle(SubmitDocumentsCommand request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorUserId, cancellationToken);

        if (doctorProfile is null || doctorProfile.User.Role != UserRole.Doctor)
        {
            throw new NotFoundException("Doctor profile not found.");
        }

        if (doctorProfile.Status != DoctorStatus.PendingReview)
        {
            throw new BadRequestException("Documents can only be uploaded while pending review.");
        }

        var uploaded = new List<UploadedDoctorDocumentDto>();
        for (var i = 0; i < request.Files.Count; i++)
        {
            var file = request.Files[i];
            var documentType = request.DocumentTypes[i];
            var folder = $"clinic/doctor-documents/{request.DoctorUserId}";
            var result = await _cloudinaryService.UploadFileAsync(file, folder);

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

        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<List<UploadedDoctorDocumentDto>>.Ok(uploaded, "Documents uploaded successfully.");
    }
}
