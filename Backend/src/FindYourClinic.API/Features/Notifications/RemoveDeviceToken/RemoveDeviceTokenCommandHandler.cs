using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Notifications.RemoveDeviceToken;

public class RemoveDeviceTokenCommandHandler : IRequestHandler<RemoveDeviceTokenCommand, ApiResponse<string>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public RemoveDeviceTokenCommandHandler(UserManager<ApplicationUser> userManager, IHttpContextAccessor httpContextAccessor)
    {
        _userManager = userManager;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<ApiResponse<string>> Handle(RemoveDeviceTokenCommand request, CancellationToken cancellationToken)
    {
        var userIdValue = _httpContextAccessor.HttpContext?.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userIdValue) || !Guid.TryParse(userIdValue, out var userId))
        {
            return ApiResponse<string>.Fail("Unauthorized.");
        }

        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return ApiResponse<string>.Fail("User not found.");
        }

        user.FcmToken = null;
        user.FcmTokenUpdatedAt = DateTime.UtcNow;

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
        {
            return ApiResponse<string>.Fail("Failed to remove device token.");
        }

        return ApiResponse<string>.Ok("ok", "Device token removed.");
    }
}
