using FluentValidation;

namespace FindYourClinic.API.Features.Reviews.AddReview;

public class AddReviewCommandValidator : AbstractValidator<AddReviewCommand>
{
    public AddReviewCommandValidator()
    {
        RuleFor(x => x.DoctorId).NotEmpty();
        RuleFor(x => x.Rating)
            .InclusiveBetween(1, 5)
            .WithMessage("Rating must be between 1 and 5.");
        RuleFor(x => x.Comment)
            .MaximumLength(1000)
            .When(x => x.Comment != null);
    }
}
