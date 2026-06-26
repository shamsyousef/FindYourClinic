using FindYourClinic.API.Features.Reviews.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Reviews.GetReviews;

public class GetDoctorReviewsQuery : IRequest<ApiResponse<ReviewListResponse>>
{
    public Guid DoctorId { get; set; }
}
