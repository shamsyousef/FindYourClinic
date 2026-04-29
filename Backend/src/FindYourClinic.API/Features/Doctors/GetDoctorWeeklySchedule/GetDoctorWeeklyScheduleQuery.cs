using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetDoctorWeeklySchedule;

public record GetDoctorWeeklyScheduleQuery(Guid DoctorUserId)
    : IRequest<ApiResponse<List<WeeklyScheduleItemDto>>>;

public sealed record WeeklyScheduleItemDto(
    string DayOfWeek,
    string StartTime,
    string EndTime);
