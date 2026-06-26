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
            .Must(f => f.Count <= 5).WithMessage("MAXIMUM_5_FILES_ALLOWED");
        RuleFor(x => x.DocumentTypes).NotEmpty();
        RuleFor(x => x)
            .Must(x => x.Files.Count == x.DocumentTypes.Count)
            .WithMessage("FILES_COUNT_MISMATCH");
        RuleForEach(x => x.Files)
            .Must(f => f.Length <= MaxFileBytes).WithMessage("FILE_UNDER_10MB")
            .Must(f => AllowedExtensions.Contains(Path.GetExtension(f.FileName).ToLowerInvariant()))
            .WithMessage("ONLY_JPG_PNG_PDF_ACCEPTED");
    }
}
