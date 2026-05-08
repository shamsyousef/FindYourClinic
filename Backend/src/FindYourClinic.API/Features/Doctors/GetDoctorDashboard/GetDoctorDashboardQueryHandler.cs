using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetDoctorDashboard;

public class GetDoctorDashboardQueryHandler
    : IRequestHandler<GetDoctorDashboardQuery, ApiResponse<DoctorDashboardDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetDoctorDashboardQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<DoctorDashboardDto>> Handle(
        GetDoctorDashboardQuery request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken);

        if (doctorProfile is null)
        {
            throw new NotFoundException("Doctor profile not found.");
        }

        var now = DateTime.UtcNow;
        var todayStart = now.Date;
        var todayEnd = todayStart.AddDays(1);

        // ─── Quick Stats ───
        var todayAppointments = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfile.Id
                        && x.ScheduledAt >= todayStart
                        && x.ScheduledAt < todayEnd)
            .ToListAsync(cancellationToken);

        var quickStats = new DoctorQuickStatsDto(
            TotalToday: todayAppointments.Count,
            Completed: todayAppointments.Count(x => x.Status == AppointmentStatus.Completed),
            Pending: todayAppointments.Count(x => x.Status == AppointmentStatus.Scheduled
                                                  || x.Status == AppointmentStatus.Confirmed),
            Cancelled: todayAppointments.Count(x => x.Status == AppointmentStatus.Cancelled));

        // ─── Overall Stats (all-time) ───
        var statusBuckets = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfile.Id)
            .GroupBy(x => x.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        int CountFor(params AppointmentStatus[] statuses) =>
            statusBuckets.Where(b => statuses.Contains(b.Status)).Sum(b => b.Count);

        var overallStats = new DoctorOverallStatsDto(
            Total: statusBuckets.Sum(b => b.Count),
            Completed: CountFor(AppointmentStatus.Completed),
            Pending: CountFor(AppointmentStatus.Scheduled, AppointmentStatus.Confirmed),
            Cancelled: CountFor(AppointmentStatus.Cancelled));

        // ─── Next Appointment ───
        var nextAppointment = await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Patient)
            .Where(x => x.DoctorProfileId == doctorProfile.Id
                        && x.ScheduledAt >= now
                        && x.Status != AppointmentStatus.Cancelled)
            .OrderBy(x => x.ScheduledAt)
            .Select(x => new DoctorNextAppointmentDto(
                x.Id,
                x.ScheduledAt,
                x.Status.ToString(),
                x.LocationName,
                x.PatientId,
                $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                x.Patient.ProfileImageUrl))
            .FirstOrDefaultAsync(cancellationToken);

        // ─── Performance Summary ───
        var totalPatientsCount = await _dbContext.Appointments
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfile.Id
                        && x.Status == AppointmentStatus.Completed)
            .Select(x => x.PatientId)
            .Distinct()
            .CountAsync(cancellationToken);

        var avgRating = await _dbContext.DoctorReviews
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfile.Id)
            .Select(x => (double?)x.Rating)
            .AverageAsync(cancellationToken) ?? 0;

        var totalReviews = await _dbContext.DoctorReviews
            .AsNoTracking()
            .CountAsync(x => x.DoctorProfileId == doctorProfile.Id, cancellationToken);

        var performance = new DoctorPerformanceDto(
            TotalPatients: totalPatientsCount,
            AverageRating: Math.Round(avgRating, 2),
            TotalReviews: totalReviews);

        // ─── Today's Schedule ───
        var schedule = await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.Patient)
            .Where(x => x.DoctorProfileId == doctorProfile.Id
                        && x.ScheduledAt >= todayStart
                        && x.ScheduledAt < todayEnd
                        && x.Status != AppointmentStatus.Cancelled)
            .OrderBy(x => x.ScheduledAt)
            .Select(x => new DoctorScheduleItemDto(
                x.Id,
                x.ScheduledAt,
                x.Status.ToString(),
                x.PatientId,
                $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                x.Patient.ProfileImageUrl))
            .ToListAsync(cancellationToken);

        var dashboard = new DoctorDashboardDto(quickStats, overallStats, nextAppointment, performance, schedule);
        return ApiResponse<DoctorDashboardDto>.Ok(dashboard);
    }
}
