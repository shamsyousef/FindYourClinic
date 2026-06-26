using Ardalis.Result;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Interfaces;
using MediatR;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Users.UpdateProfileImage;

public class UpdateProfileImageCommandHandler : IRequestHandler<UpdateProfileImageCommand, Result<string>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ICloudinaryService _cloudinaryService;

    public UpdateProfileImageCommandHandler(
        UserManager<ApplicationUser> userManager,
        ICloudinaryService cloudinaryService)
    {
        _userManager = userManager;
        _cloudinaryService = cloudinaryService;
    }

    public async Task<Result<string>> Handle(UpdateProfileImageCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByIdAsync(request.UserId.ToString());
        if (user == null)
        {
            return Result.NotFound("USER_NOT_FOUND");
        }

        try
        {
            // Upload new image
            var uploadResult = await _cloudinaryService.UploadImageAsync(request.File, "profile-images");

            // Delete old image if exists
            if (!string.IsNullOrEmpty(user.CloudinaryPublicId))
            {
                try
                {
                    await _cloudinaryService.DeleteFileAsync(user.CloudinaryPublicId);
                }
                catch
                {
                    // Log error but don't fail the request if deletion fails
                }
            }

            // Update user
            user.ProfileImageUrl = uploadResult.Url;
            user.CloudinaryPublicId = uploadResult.PublicId;
            user.UpdatedAt = DateTime.UtcNow;

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
            {
                return Result.Error("FAILED_TO_UPDATE_PROFILE_IMAGE");
            }

            return Result.Success(user.ProfileImageUrl, "PROFILE_IMAGE_UPDATED_SUCCESS");
        }
        catch
        {
            return Result.Error("IMAGE_UPLOAD_FAILED");
        }
    }
}
