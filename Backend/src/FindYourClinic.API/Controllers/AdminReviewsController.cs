using FindYourClinic.API.Features.Reviews.DeleteReview;
using FindYourClinic.API.Features.Reviews.GetAllReviews;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/admin/reviews")]
[Authorize(Policy = "AdminOnly")]
public class AdminReviewsController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminReviewsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllReviews(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAllReviewsQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpDelete("{reviewId:guid}")]
    public async Task<IActionResult> DeleteReview([FromRoute] Guid reviewId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteReviewCommand { ReviewId = reviewId }, cancellationToken);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
