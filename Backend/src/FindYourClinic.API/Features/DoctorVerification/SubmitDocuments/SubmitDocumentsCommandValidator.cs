using FluentValidation;

namespace FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;

public class SubmitDocumentsCommandValidator : AbstractValidator<SubmitDocumentsCommand>
{
    public SubmitDocumentsCommandValidator()
    {
        RuleFor(x => x.DoctorUserId).NotEmpty();
        RuleFor(x => x.Files).NotEmpty();
        RuleFor(x => x.DocumentTypes).NotEmpty();
        RuleFor(x => x)
            .Must(x => x.Files.Count == x.DocumentTypes.Count)
            .WithMessage("Files count must match documentTypes count.");
    }
}
