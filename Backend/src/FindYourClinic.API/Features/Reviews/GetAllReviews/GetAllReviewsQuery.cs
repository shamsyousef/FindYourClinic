using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Reviews.GetAllReviews;

public class GetAllReviewsQuery : IRequest<ApiResponse<List<AdminReviewDto>>>
{
}

public sealed record AdminReviewDto(
    Guid Id,
    string DoctorName,
    Guid DoctorId,
    string PatientName,
    int Rating,
    string? Comment,
    DateTime CreatedAt);
