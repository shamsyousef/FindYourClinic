using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetDoctorById;

public class GetDoctorByIdQuery : IRequest<ApiResponse<DoctorDetailsDto>>
{
    public Guid DoctorId { get; set; }
}
