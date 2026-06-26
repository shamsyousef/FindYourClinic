using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorVerification.GetPendingDoctors;

public class GetPendingDoctorsQueryHandler : IRequestHandler<GetPendingDoctorsQuery, ApiResponse<List<PendingDoctorDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetPendingDoctorsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<PendingDoctorDto>>> Handle(GetPendingDoctorsQuery request, CancellationToken cancellationToken)
    {
        var doctors = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Include(x => x.User)
            .Include(x => x.Specialty)
            .Include(x => x.Documents)
            .Where(x => x.Status == DoctorStatus.PendingReview)
            .Select(x => new PendingDoctorDto
            {
                DoctorId = x.UserId,
                Email = x.User.Email ?? string.Empty,
                FullName = $"{x.User.FirstName} {x.User.LastName}".Trim(),
                Specialty = x.Specialty.Name,
                DocumentUrls = x.Documents.Select(d => d.FileUrl).ToList()
            })
            .ToListAsync(cancellationToken);

        return ApiResponse<List<PendingDoctorDto>>.Ok(doctors);
    }
}
