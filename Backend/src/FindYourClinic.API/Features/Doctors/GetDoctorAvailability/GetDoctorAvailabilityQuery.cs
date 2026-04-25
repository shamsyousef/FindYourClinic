using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetDoctorAvailability;

public class GetDoctorAvailabilityQuery : IRequest<ApiResponse<List<DateTime>>>
{
    public Guid DoctorId { get; set; }
    public DateOnly? Date { get; set; }
}
