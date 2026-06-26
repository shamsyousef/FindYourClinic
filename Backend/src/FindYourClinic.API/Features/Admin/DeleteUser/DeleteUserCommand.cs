using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.DeleteUser;

public class DeleteUserCommand : IRequest<ApiResponse<object>>
{
    public Guid UserId { get; set; }
    public string Reason { get; set; } = string.Empty;
}