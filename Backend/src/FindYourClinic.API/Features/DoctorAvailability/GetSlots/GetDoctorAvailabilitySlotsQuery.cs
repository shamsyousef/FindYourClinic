using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.DoctorAvailability.GetSlots;

public class GetDoctorAvailabilitySlotsQuery : IRequest<ApiResponse<List<DateTime>>>
{
    public Guid DoctorId { get; set; }
    public DateOnly Date { get; set; }
}
