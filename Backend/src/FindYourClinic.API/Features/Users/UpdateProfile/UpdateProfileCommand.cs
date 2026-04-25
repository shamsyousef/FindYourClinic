using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Users.UpdateProfile;

public class UpdateProfileCommand : IRequest<ApiResponse<object>>
{
    public Guid UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}
