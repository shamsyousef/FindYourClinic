using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Users.RequestAccountDeletion;

public class RequestAccountDeletionCommand : IRequest<ApiResponse<object>>
{
    public Guid UserId { get; set; }
    public string Password { get; set; } = string.Empty;
}
