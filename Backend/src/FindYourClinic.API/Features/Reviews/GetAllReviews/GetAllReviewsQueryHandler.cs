using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Reviews.GetAllReviews;

public class GetAllReviewsQueryHandler : IRequestHandler<GetAllReviewsQuery, ApiResponse<List<AdminReviewDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetAllReviewsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<AdminReviewDto>>> Handle(GetAllReviewsQuery request, CancellationToken cancellationToken)
    {
        var reviews = await _dbContext.DoctorReviews
            .AsNoTracking()
            .Include(x => x.Patient)
            .Include(x => x.DoctorProfile)
                .ThenInclude(dp => dp.User)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AdminReviewDto(
                x.Id,
                $"{x.DoctorProfile.User.FirstName} {x.DoctorProfile.User.LastName}".Trim(),
                x.DoctorProfile.UserId,
                $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                x.Rating,
                x.Comment,
                x.CreatedAt))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<AdminReviewDto>>.Ok(reviews);
    }
}
