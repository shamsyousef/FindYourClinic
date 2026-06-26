using FluentValidation;

namespace FindYourClinic.API.Features.Reviews.AddReview;

public class AddReviewCommandValidator : AbstractValidator<AddReviewCommand>
{
    public AddReviewCommandValidator()
    {
        RuleFor(x => x.DoctorId).NotEmpty();
        RuleFor(x => x.Rating)
            .InclusiveBetween(1, 5)
            .WithMessage("RATING_MUST_BE_BETWEEN_1_AND_5");
        RuleFor(x => x.Comment)
            .MaximumLength(1000)
            .When(x => x.Comment != null);
    }
}
