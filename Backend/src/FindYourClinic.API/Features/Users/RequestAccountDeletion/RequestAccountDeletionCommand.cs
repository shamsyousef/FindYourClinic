using Ardalis.Result;
using MediatR;

namespace FindYourClinic.API.Features.Users.RequestAccountDeletion;

public class RequestAccountDeletionCommand : IRequest<Result>
{
    public Guid UserId { get; set; }
    public string Password { get; set; } = string.Empty;
}
