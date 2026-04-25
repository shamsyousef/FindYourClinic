using FluentValidation;

namespace FindYourClinic.API.Features.Users.GetProfile;

public class GetProfileQueryValidator : AbstractValidator<GetProfileQuery>
{
    public GetProfileQueryValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
    }
}
