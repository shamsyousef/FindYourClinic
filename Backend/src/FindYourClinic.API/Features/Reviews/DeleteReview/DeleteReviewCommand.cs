using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Reviews.DeleteReview;

public class DeleteReviewCommand : IRequest<ApiResponse<object>>
{
    public Guid ReviewId { get; set; }
}
