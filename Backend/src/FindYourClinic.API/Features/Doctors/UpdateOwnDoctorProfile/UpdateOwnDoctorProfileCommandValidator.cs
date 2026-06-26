using FluentValidation;

namespace FindYourClinic.API.Features.Doctors.UpdateOwnDoctorProfile;

public class UpdateOwnDoctorProfileCommandValidator : AbstractValidator<UpdateOwnDoctorProfileCommand>
{
    public UpdateOwnDoctorProfileCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.SpecialtyId).NotEmpty();
    }
}
