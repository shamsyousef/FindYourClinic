using FluentValidation;

namespace FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;

public class SubmitDocumentsCommandValidator : AbstractValidator<SubmitDocumentsCommand>
{
    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".pdf"];
    private const long MaxFileBytes = 10 * 1024 * 1024;

    public SubmitDocumentsCommandValidator()
    {
        RuleFor(x => x.DoctorUserId).NotEmpty();
        RuleFor(x => x.Files)
            .NotEmpty()
            .Must(f => f.Count <= 5).WithMessage("Maximum 5 files allowed.");
        RuleFor(x => x.DocumentTypes).NotEmpty();
        RuleFor(x => x)
            .Must(x => x.Files.Count == x.DocumentTypes.Count)
            .WithMessage("Files count must match documentTypes count.");
        RuleForEach(x => x.Files)
            .Must(f => f.Length <= MaxFileBytes).WithMessage("Each file must be under 10 MB.")
            .Must(f => AllowedExtensions.Contains(Path.GetExtension(f.FileName).ToLowerInvariant()))
            .WithMessage("Only JPG, PNG, and PDF files are accepted.");
    }
}
