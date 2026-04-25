using System.Security.Claims;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;

namespace FindYourClinic.API.Common;

public static class UserContext
{
    public static Guid GetRequiredUserId(ClaimsPrincipal user)
    {
        var raw = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(raw) || !Guid.TryParse(raw, out var parsed))
        {
            throw new UnauthorizedException("Invalid user token.");
        }

        return parsed;
    }

    public static UserRole GetRequiredRole(ClaimsPrincipal user)
    {
        var raw = user.FindFirstValue(ClaimTypes.Role);
        if (string.IsNullOrWhiteSpace(raw) || !Enum.TryParse<UserRole>(raw, true, out var role))
        {
            throw new UnauthorizedException("Invalid role claim.");
        }

        return role;
    }
}
