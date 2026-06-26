using FindYourClinic.API.Common;
using FindYourClinic.API.Features.Reviews.AddReview;
using FindYourClinic.API.Features.Reviews.GetReviews;
using FindYourClinic.API.Localization;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/doctors/{doctorId:guid}/reviews")]
public class ReviewsController : ControllerBase
{
    private readonly IMediator _mediator;

    public ReviewsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetReviews([FromRoute] Guid doctorId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorReviewsQuery
        {
            DoctorId = doctorId
        }, cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> AddReview([FromRoute] Guid doctorId, [FromBody] AddReviewRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new AddReviewCommand
        {
            DoctorId = doctorId,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            Rating = request.Rating,
            Comment = request.Comment
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    public sealed class AddReviewRequest
    {
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
