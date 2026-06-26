using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Controllers;

public class MarkAsPaidCommand : IRequest<Result<string>>
{
    public Guid AppointmentId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
