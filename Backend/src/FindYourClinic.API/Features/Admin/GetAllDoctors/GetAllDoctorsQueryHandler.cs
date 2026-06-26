using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetAllDoctors;

public class GetAllDoctorsQueryHandler : IRequestHandler<GetAllDoctorsQuery, ApiResponse<List<AllDoctorDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetAllDoctorsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<AllDoctorDto>>> Handle(GetAllDoctorsQuery request, CancellationToken cancellationToken)
    {
        var query = _dbContext.DoctorProfiles
            .AsNoTracking()
            .Include(x => x.User)
            .Include(x => x.Specialty)
            .Include(x => x.Documents)
            .AsQueryable();

        if (request.Status.HasValue)
            query = query.Where(x => x.Status == request.Status.Value);

        var doctors = await query
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AllDoctorDto
            {
                DoctorId = x.UserId,
                UserId = x.UserId,
                FullName = $"{x.User.FirstName} {x.User.LastName}".Trim(),
                Email = x.User.Email ?? string.Empty,
                Specialty = x.Specialty.Name,
                Status = x.Status.ToString(),
                IsActive = x.User.IsActive,
                ReviewedAt = x.ReviewedAt,
                RejectionReason = x.RejectionReason,
                DocumentUrls = x.Documents.Select(d => d.FileUrl).ToList()
            })
            .ToListAsync(cancellationToken);

        return ApiResponse<List<AllDoctorDto>>.Ok(doctors);
    }
}
