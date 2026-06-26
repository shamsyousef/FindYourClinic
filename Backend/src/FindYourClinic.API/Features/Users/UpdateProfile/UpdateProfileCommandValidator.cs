using FluentValidation;

namespace FindYourClinic.API.Features.Users.UpdateProfile;

public class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
{
    public UpdateProfileCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.PhoneNumber).MaximumLength(30).When(x => x.PhoneNumber != null);
        RuleFor(x => x.Gender).MaximumLength(50).When(x => x.Gender != null);
        RuleFor(x => x.BloodType).MaximumLength(10).When(x => x.BloodType != null);
        RuleFor(x => x.Address).MaximumLength(500).When(x => x.Address != null);
        RuleFor(x => x.EmergencyContactName).MaximumLength(150).When(x => x.EmergencyContactName != null);
        RuleFor(x => x.EmergencyContactPhone).MaximumLength(30).When(x => x.EmergencyContactPhone != null);
    }
}
