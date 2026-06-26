using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.Shared;

public class DoctorAvailabilitySlotsService
{
    private readonly ApplicationDbContext _dbContext;

    public DoctorAvailabilitySlotsService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<DateTime>> BuildAvailableSlotsAsync(Guid doctorProfileId, DateOnly date, CancellationToken cancellationToken)
    {
        var day = date.DayOfWeek;
        var startOfDay = date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var endOfDay = date.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc);

        var windows = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfileId && x.IsActive && x.DayOfWeek == day)
            .ToListAsync(cancellationToken);

        var bookedSlots = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfileId &&
                        x.ScheduledAt >= startOfDay &&
                        x.ScheduledAt <= endOfDay &&
                        x.Status != AppointmentStatus.Cancelled)
            .Select(x => x.ScheduledAt)
            .ToListAsync(cancellationToken);

        var slotSet = new HashSet<DateTime>(bookedSlots);
        var slots = new List<DateTime>();

        foreach (var window in windows)
        {
            var slotTime = window.StartTime;
            while (slotTime < window.EndTime)
            {
                var slot = date.ToDateTime(TimeOnly.FromTimeSpan(slotTime), DateTimeKind.Utc);
                if (slot > DateTime.UtcNow && !slotSet.Contains(slot))
                {
                    slots.Add(slot);
                }

                slotTime = slotTime.Add(TimeSpan.FromMinutes(30));
            }
        }

        return slots.OrderBy(x => x).ToList();
    }

    public async Task<DateTime?> GetNextAvailableSlotAsync(Guid doctorProfileId, DateTime fromUtc, CancellationToken cancellationToken)
    {
        var result = await GetNextAvailableSlotsAsync([doctorProfileId], fromUtc, cancellationToken);
        return result.GetValueOrDefault(doctorProfileId);
    }

    public async Task<Dictionary<Guid, DateTime?>> GetNextAvailableSlotsAsync(IEnumerable<Guid> doctorProfileIds, DateTime fromUtc, CancellationToken cancellationToken)
    {
        const int horizonDays = 30;
        var profileIds = doctorProfileIds.Distinct().ToList();
        var output = profileIds.ToDictionary(x => x, _ => (DateTime?)null);
        if (profileIds.Count == 0)
        {
            return output;
        }

        var startDate = DateOnly.FromDateTime(fromUtc.Date);
        var endDate = startDate.AddDays(horizonDays);

        var availabilities = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .Where(x => profileIds.Contains(x.DoctorProfileId) && x.IsActive)
            .ToListAsync(cancellationToken);

        var bookedSlots = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x => profileIds.Contains(x.DoctorProfileId) &&
                        x.ScheduledAt >= startDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc) &&
                        x.ScheduledAt <= endDate.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc) &&
                        x.Status != AppointmentStatus.Cancelled)
            .Select(x => new { x.DoctorProfileId, x.ScheduledAt })
            .ToListAsync(cancellationToken);

        var bookedLookup = bookedSlots
            .GroupBy(x => x.DoctorProfileId)
            .ToDictionary(g => g.Key, g => g.Select(x => x.ScheduledAt).ToHashSet());

        foreach (var profileId in profileIds)
        {
            var profileAvailability = availabilities.Where(x => x.DoctorProfileId == profileId).ToList();
            var profileBooked = bookedLookup.GetValueOrDefault(profileId, []);

            for (var dayOffset = 0; dayOffset <= horizonDays; dayOffset++)
            {
                var date = startDate.AddDays(dayOffset);
                var windows = profileAvailability
                    .Where(x => x.DayOfWeek == date.DayOfWeek)
                    .OrderBy(x => x.StartTime)
                    .ToList();

                foreach (var window in windows)
                {
                    var slotTime = window.StartTime;
                    while (slotTime < window.EndTime)
                    {
                        var slot = date.ToDateTime(TimeOnly.FromTimeSpan(slotTime), DateTimeKind.Utc);
                        if (slot >= fromUtc &&
                            slot.Minute % 30 == 0 &&
                            !profileBooked.Contains(slot))
                        {
                            output[profileId] = slot;
                            goto FoundSlot;
                        }

                        slotTime = slotTime.Add(TimeSpan.FromMinutes(30));
                    }
                }
            }

        FoundSlot: ;
        }

        return output;
    }

    public static (DateTime From, DateTime To) GetAvailabilityWindow(string availability, DateTime now)
    {
        return availability.ToLowerInvariant() switch
        {
            "today" => (now.Date, now.Date.AddDays(1).AddTicks(-1)),
            "tomorrow" => (now.Date.AddDays(1), now.Date.AddDays(2).AddTicks(-1)),
            "this_week" => (now.Date, now.Date.AddDays(7).AddTicks(-1)),
            _ => (DateTime.MinValue, DateTime.MaxValue)
        };
    }
}
