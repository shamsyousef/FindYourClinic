using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Appointments.BookAppointment;

public class BookAppointmentCommand : IRequest<ApiResponse<AppointmentDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public Guid DoctorProfileId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? LocationName { get; set; }
}
