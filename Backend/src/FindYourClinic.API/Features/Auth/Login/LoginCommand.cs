using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Models;
using MediatR;

namespace FindYourClinic.API.Features.Auth.Login;

public class LoginCommand : IRequest<ApiResponse<AuthResponse>>
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
