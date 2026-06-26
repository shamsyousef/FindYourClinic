using FluentValidation;

namespace FindYourClinic.API.Features.DoctorVerification.GetPendingDoctors;

public class GetPendingDoctorsQueryValidator : AbstractValidator<GetPendingDoctorsQuery>
{
    public GetPendingDoctorsQueryValidator()
    {
    }
}
