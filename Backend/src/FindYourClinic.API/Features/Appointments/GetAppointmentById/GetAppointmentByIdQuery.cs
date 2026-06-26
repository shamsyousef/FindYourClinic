using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Appointments.GetAppointmentById;

public class GetAppointmentByIdQuery : IRequest<ApiResponse<AppointmentDto>>
{
    public Guid AppointmentId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
