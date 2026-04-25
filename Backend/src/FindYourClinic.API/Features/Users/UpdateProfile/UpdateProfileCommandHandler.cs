using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using MediatR;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Users.UpdateProfile;

public class UpdateProfileCommandHandler : IRequestHandler<UpdateProfileCommand, ApiResponse<object>>
{
    private readonly UserManager<Domain.Entities.ApplicationUser> _userManager;

    public UpdateProfileCommandHandler(UserManager<Domain.Entities.ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public async Task<ApiResponse<object>> Handle(UpdateProfileCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByIdAsync(request.UserId.ToString())
            ?? throw new NotFoundException("User not found.");

        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
        {
            throw new BadRequestException("Unable to update profile.");
        }

        return ApiResponse<object>.Ok(null, "Profile updated successfully.");
    }
}
