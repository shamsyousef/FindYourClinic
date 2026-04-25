using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Auth.ForgotPassword;

public class ForgotPasswordCommand : IRequest<ApiResponse<object>>
{
    public string Email { get; set; } = string.Empty;
}
