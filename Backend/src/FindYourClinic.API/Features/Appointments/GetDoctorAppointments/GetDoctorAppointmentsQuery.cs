using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Appointments.GetDoctorAppointments;

public class GetDoctorAppointmentsQuery : IRequest<ApiResponse<List<AppointmentDto>>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
