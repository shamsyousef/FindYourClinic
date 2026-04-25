using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Models;
using MediatR;

namespace FindYourClinic.API.Features.Auth.RefreshToken;

public class RefreshTokenCommand : IRequest<ApiResponse<AuthResponse>>
{
    public string RefreshToken { get; set; } = string.Empty;
}
