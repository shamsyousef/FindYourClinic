using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Auth.ResetPassword;

public class ResetPasswordCommand : IRequest<ApiResponse<object>>
{
    public string Token { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
