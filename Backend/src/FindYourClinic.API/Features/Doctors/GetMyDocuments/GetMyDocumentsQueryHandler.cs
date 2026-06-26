using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetMyDocuments;

public class GetMyDocumentsQueryHandler : IRequestHandler<GetMyDocumentsQuery, ApiResponse<List<MyDoctorDocumentDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetMyDocumentsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<MyDoctorDocumentDto>>> Handle(GetMyDocumentsQuery request, CancellationToken cancellationToken)
    {
        var profileId = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.UserId == request.UserId)
            .Select(x => x.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (profileId == Guid.Empty)
            throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        var documents = await _dbContext.DoctorDocuments
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == profileId)
            .OrderByDescending(x => x.UploadedAt)
            .Select(x => new MyDoctorDocumentDto
            {
                DocumentType = x.DocumentType,
                Url = x.FileUrl,
                UploadedAt = x.UploadedAt
            })
            .ToListAsync(cancellationToken);

        return ApiResponse<List<MyDoctorDocumentDto>>.Ok(documents);
    }
}
