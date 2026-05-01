using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Reviews.DeleteReview;

public class DeleteReviewCommandHandler : IRequestHandler<DeleteReviewCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;

    public DeleteReviewCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(DeleteReviewCommand request, CancellationToken cancellationToken)
    {
        var review = await _dbContext.DoctorReviews
            .FirstOrDefaultAsync(x => x.Id == request.ReviewId, cancellationToken)
            ?? throw new NotFoundException("Review not found.");

        _dbContext.DoctorReviews.Remove(review);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<object>.Ok(null, "Review deleted.");
    }
}
