using Ardalis.Result;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Reviews.DeleteReview;

public class DeleteReviewCommandHandler : IRequestHandler<DeleteReviewCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;

    public DeleteReviewCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result> Handle(DeleteReviewCommand request, CancellationToken cancellationToken)
    {
        var review = await _dbContext.DoctorReviews
            .FirstOrDefaultAsync(x => x.Id == request.ReviewId, cancellationToken)
            ?? throw new NotFoundException("REVIEW_NOT_FOUND");

        _dbContext.DoctorReviews.Remove(review);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return Result.Success("REVIEW_DELETED_SUCCESS");
    }
}
