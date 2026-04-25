using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Models;
using MediatR;

namespace FindYourClinic.API.Features.Auth.Register;

public class RegisterCommand : IRequest<ApiResponse<RegisterResultDto>>
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? FullName { get; set; }
    public Guid? SpecialtyId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}

public class RegisterResultDto
{
    public AuthResponse? Auth { get; set; }
    public string? PendingToken { get; set; }
}
