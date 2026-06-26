using Ardalis.Result;
using MediatR;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class RejectDoctorCommand : IRequest<Result>
{
    public Guid DoctorId { get; set; }
    public Guid AdminId { get; set; }
    public string Reason { get; set; } = string.Empty;
}
