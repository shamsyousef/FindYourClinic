using FluentValidation;

namespace FindYourClinic.API.Features.Notifications.UpdateDeviceToken;

public class UpdateDeviceTokenCommandValidator : AbstractValidator<UpdateDeviceTokenCommand>
{
    public UpdateDeviceTokenCommandValidator()
    {
        RuleFor(x => x.Token)
            .NotEmpty()
            .MinimumLength(100);
    }
}
