using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Users.GetProfile;

public class GetProfileQuery : IRequest<ApiResponse<UserProfileDto>>
{
    public Guid UserId { get; set; }
}

public class UserProfileDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
}
