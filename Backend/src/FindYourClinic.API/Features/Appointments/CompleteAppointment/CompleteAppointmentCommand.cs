using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Appointments.CompleteAppointment;

public class CompleteAppointmentCommand : IRequest<ApiResponse<object>>
{
    public Guid AppointmentId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
