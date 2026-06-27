using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.DoctorVerification.ReviewDoctor;

public class ApproveDoctorCommand : IRequest<ApiResponse<object>>
{
    public Guid DoctorId { get; set; }
    public Guid AdminId { get; set; }
}
