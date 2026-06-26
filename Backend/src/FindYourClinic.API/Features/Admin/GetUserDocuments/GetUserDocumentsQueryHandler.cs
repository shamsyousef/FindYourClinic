using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetUserDocuments;

public class GetUserDocumentsQueryHandler : IRequestHandler<GetUserDocumentsQuery, ApiResponse<List<DocumentDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetUserDocumentsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<DocumentDto>>> Handle(GetUserDocumentsQuery request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == request.UserId, cancellationToken)
            ?? throw new NotFoundException("USER_NOT_FOUND");

        if (user.Role == UserRole.Doctor)
        {
            var doctorProfile = await _dbContext.DoctorProfiles
                .AsNoTracking()
                .Include(x => x.Documents)
                .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken);

            if (doctorProfile is null)
                return ApiResponse<List<DocumentDto>>.Ok([]);

            var docs = doctorProfile.Documents
                .Select(d => new DocumentDto
                {
                    Url = d.FileUrl,
                    Name = d.DocumentType,
                    Type = "VerificationDocument",
                    UploadedAt = d.UploadedAt
                })
                .ToList();

            return ApiResponse<List<DocumentDto>>.Ok(docs);
        }

        var healthRecords = await _dbContext.HealthRecords
            .AsNoTracking()
            .Where(r => r.PatientId == request.UserId)
            .OrderByDescending(r => r.RecordedAt)
            .Select(r => new DocumentDto
            {
                Url = r.FileUrl??string.Empty,
                Name = r.Title,
                Type = r.Type.ToString(),
                UploadedAt = r.RecordedAt
            })
            .ToListAsync(cancellationToken);

        return ApiResponse<List<DocumentDto>>.Ok(healthRecords);
    }
}
