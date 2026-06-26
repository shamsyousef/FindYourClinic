using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetDoctorWeeklySchedule;

public class GetDoctorWeeklyScheduleQueryHandler
    : IRequestHandler<GetDoctorWeeklyScheduleQuery, ApiResponse<List<WeeklyScheduleItemDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorWeeklyScheduleQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<WeeklyScheduleItemDto>>> Handle(
        GetDoctorWeeklyScheduleQuery request, CancellationToken cancellationToken)
    {
        var doctorProfileId = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.UserId == request.DoctorUserId && x.Status == DoctorStatus.Approved)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("DOCTOR_NOT_FOUND");

        var rules = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfileId && x.IsActive)
            .OrderBy(x => x.DayOfWeek)
            .Select(x => new WeeklyScheduleItemDto(
                x.DayOfWeek.ToString(),
                x.StartTime.ToString(@"hh\:mm"),
                x.EndTime.ToString(@"hh\:mm")))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<WeeklyScheduleItemDto>>.Ok(rules);
    }
}
