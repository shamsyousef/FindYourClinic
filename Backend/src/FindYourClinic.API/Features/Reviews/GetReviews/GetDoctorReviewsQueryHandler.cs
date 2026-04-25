using FindYourClinic.API.Features.Reviews.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Reviews.GetReviews;

public class GetDoctorReviewsQueryHandler : IRequestHandler<GetDoctorReviewsQuery, ApiResponse<ReviewListResponse>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorReviewsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<ReviewListResponse>> Handle(GetDoctorReviewsQuery request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId && x.Status == DoctorStatus.Approved, cancellationToken)
            ?? throw new NotFoundException("Doctor not found.");

        var reviews = await _dbContext.DoctorReviews
            .AsNoTracking()
            .Include(x => x.Patient)
            .Where(x => x.DoctorProfileId == doctorProfile.Id)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new ReviewDto(
                x.Id,
                x.PatientId,
                $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                x.Rating,
                x.Comment,
                x.CreatedAt))
            .ToListAsync(cancellationToken);

        var avg = reviews.Count == 0 ? 0 : Math.Round(reviews.Average(x => x.Rating), 2);
        return ApiResponse<ReviewListResponse>.Ok(new ReviewListResponse(avg, reviews.Count, reviews));
    }
}
