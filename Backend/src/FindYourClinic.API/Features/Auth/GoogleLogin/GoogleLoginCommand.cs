using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Models;
using MediatR;

namespace FindYourClinic.API.Features.Auth.GoogleLogin;

public class GoogleLoginCommand : IRequest<ApiResponse<GoogleLoginResultDto>>
{
    public string IdToken { get; set; } = string.Empty;
    public string? Role { get; set; }
    public Guid? SpecialtyId { get; set; }
}

public class GoogleLoginResultDto
{
    public AuthResponse? Auth { get; set; }
    public string? PendingToken { get; set; }
}
