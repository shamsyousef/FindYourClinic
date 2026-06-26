using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Users.GetProfile;

public class GetProfileQueryHandler : IRequestHandler<GetProfileQuery, ApiResponse<UserProfileDto>>
{
    private readonly UserManager<Domain.Entities.ApplicationUser> _userManager;

    public GetProfileQueryHandler(UserManager<Domain.Entities.ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public async Task<ApiResponse<UserProfileDto>> Handle(GetProfileQuery request, CancellationToken cancellationToken)
    {
        var user = await _userManager.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == request.UserId, cancellationToken)
            ?? throw new NotFoundException("USER_NOT_FOUND");

        var profile = new UserProfileDto
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
        };

        return ApiResponse<UserProfileDto>.Ok(profile);
    }
}
