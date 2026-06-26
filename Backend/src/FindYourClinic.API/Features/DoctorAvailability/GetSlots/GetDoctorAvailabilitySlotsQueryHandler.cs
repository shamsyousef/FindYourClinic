using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorAvailability.GetSlots;

public class GetDoctorAvailabilitySlotsQueryHandler 
    : IRequestHandler<GetDoctorAvailabilitySlotsQuery, ApiResponse<List<DateTime>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorAvailabilitySlotsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<DateTime>>> Handle(
        GetDoctorAvailabilitySlotsQuery request,
        CancellationToken cancellationToken)
    {
        var doctorProfileId = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.UserId == request.DoctorId && x.Status == DoctorStatus.Approved)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("DOCTOR_NOT_FOUND");


        var slots = await BuildAvailableSlotsAsync(
            doctorProfileId,
            request.Date,
            cancellationToken);

        return ApiResponse<List<DateTime>>.Ok(slots);
    }


    private async Task<List<DateTime>> BuildAvailableSlotsAsync(
        Guid doctorProfileId,
        DateOnly date,
        CancellationToken cancellationToken)
    {
        var startOfDay = date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var endOfDay = date.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc);


        var windows = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .Where(x =>
                x.DoctorProfileId == doctorProfileId &&
                x.IsActive &&
                x.DayOfWeek == date.DayOfWeek)
            .ToListAsync(cancellationToken);


        var booked = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x =>
                x.DoctorProfileId == doctorProfileId &&
                x.ScheduledAt >= startOfDay &&
                x.ScheduledAt <= endOfDay &&
                x.Status != AppointmentStatus.Cancelled)
            .Select(x => x.ScheduledAt)
            .ToListAsync(cancellationToken);


        var bookedSet = new HashSet<DateTime>(booked);
        var slots = new List<DateTime>();


        foreach (var window in windows)
        {
            var current = window.StartTime;

            while (current < window.EndTime)
            {
                var dateTime = date.ToDateTime(
                    TimeOnly.FromTimeSpan(current),
                    DateTimeKind.Utc);


                if (dateTime > DateTime.UtcNow &&
                    !bookedSet.Contains(dateTime))
                {
                    slots.Add(dateTime);
                }

                current = current.Add(TimeSpan.FromMinutes(30));
            }
        }


        return slots.OrderBy(x => x).ToList();
    }
}