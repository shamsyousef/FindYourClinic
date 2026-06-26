using Ardalis.Result;
using MediatR;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class ApproveDoctorCommand : IRequest<Result>
{
    public Guid DoctorId { get; set; }
    public Guid AdminId { get; set; }
}
