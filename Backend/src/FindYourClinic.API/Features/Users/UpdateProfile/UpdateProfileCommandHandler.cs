using Ardalis.Result;
using FindYourClinic.API.Features.Users.GetProfile;
using FindYourClinic.Domain.Exceptions;
using MediatR;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Users.UpdateProfile;

public class UpdateProfileCommandHandler : IRequestHandler<UpdateProfileCommand, Result<UserProfileDto>>
{
    private readonly UserManager<Domain.Entities.ApplicationUser> _userManager;

    public UpdateProfileCommandHandler(UserManager<Domain.Entities.ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public async Task<Result<UserProfileDto>> Handle(UpdateProfileCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByIdAsync(request.UserId.ToString())
            ?? throw new NotFoundException("USER_NOT_FOUND");

        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.PhoneNumber = request.PhoneNumber?.Trim();
        user.DateOfBirth = request.DateOfBirth;
        user.Gender = request.Gender?.Trim();
        user.BloodType = request.BloodType?.Trim();
        user.Address = request.Address?.Trim();
        user.EmergencyContactName = request.EmergencyContactName?.Trim();
        user.EmergencyContactPhone = request.EmergencyContactPhone?.Trim();

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
            throw new BadRequestException("UNABLE_TO_UPDATE_PROFILE");

        return Result.Success(new UserProfileDto
        {
            Id = user.Id,
            Email = user.Email ?? string.Empty,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Role = user.Role.ToString(),
            ProfileImageUrl = user.ProfileImageUrl,
            PhoneNumber = user.PhoneNumber,
            DateOfBirth = user.DateOfBirth,
            Gender = user.Gender,
            BloodType = user.BloodType,
            Address = user.Address,
            EmergencyContactName = user.EmergencyContactName,
            EmergencyContactPhone = user.EmergencyContactPhone
        }, "PROFILE_UPDATED_SUCCESS");
    }
}
