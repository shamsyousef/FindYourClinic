using FindYourClinic.API.Features.DoctorAvailability.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.DoctorAvailability.UpdateAvailability;

public class UpdateAvailabilityCommand : IRequest<ApiResponse<AvailabilityDto>>
{
    public Guid AvailabilityId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsActive { get; set; } = true;
}
