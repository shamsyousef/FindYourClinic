using Ardalis.Result;
using MediatR;

namespace FindYourClinic.API.Features.Reviews.DeleteReview;

public class DeleteReviewCommand : IRequest<Result>
{
    public Guid ReviewId { get; set; }
}
