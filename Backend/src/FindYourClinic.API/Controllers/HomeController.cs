using FindYourClinic.API.Common;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/home")]
[Authorize]
public class HomeController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;

    public HomeController(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        if (UserContext.GetRequiredRole(User) != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access home summary.");
        }

        var now = DateTime.UtcNow;

        var upcomingAppointment = await _dbContext.Appointments
            .AsNoTracking()
            .Include(x => x.DoctorProfile).ThenInclude(x => x.User)
            .Include(x => x.DoctorProfile).ThenInclude(x => x.Specialty)
            .Where(x => x.PatientId == userId && x.ScheduledAt >= now && x.Status != AppointmentStatus.Cancelled)
            .OrderBy(x => x.ScheduledAt)
            .Select(x => new UpcomingAppointmentDto(
                x.Id,
                x.ScheduledAt,
                x.Status.ToString(),
                x.LocationName ?? x.DoctorProfile.ClinicName,
                x.DoctorProfile.UserId,
                $"{x.DoctorProfile.User.FirstName} {x.DoctorProfile.User.LastName}".Trim(),
                x.DoctorProfile.Specialty.Name))
            .FirstOrDefaultAsync(cancellationToken);

        var records = await _dbContext.HealthRecords
            .AsNoTracking()
            .Where(x => x.PatientId == userId)
            .OrderByDescending(x => x.RecordedAt)
            .ToListAsync(cancellationToken);

        var latestHeartRate = records.FirstOrDefault(x => x.Type == HealthRecordType.HeartRate);
        var latestBloodPressure = records.FirstOrDefault(x => x.Type == HealthRecordType.BloodPressure);

        var topDoctors = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Include(x => x.User)
            .Include(x => x.Specialty)
            .Where(x => x.Status == DoctorStatus.Approved && x.User.IsActive)
            .Select(x => new TopDoctorDto(
                x.UserId,
                $"{x.User.FirstName} {x.User.LastName}".Trim(),
                x.Specialty.Name,
                Math.Round(_dbContext.DoctorReviews.Where(r => r.DoctorProfileId == x.Id).Select(r => (double?)r.Rating).Average() ?? 0, 2),
                _dbContext.DoctorReviews.Count(r => r.DoctorProfileId == x.Id),
                x.ConsultationFee,
                x.Latitude,
                x.Longitude))
            .OrderByDescending(x => x.Rating)
            .ThenBy(x => x.ConsultationFee)
            .Take(5)
            .ToListAsync(cancellationToken);

        var specialties = await _dbContext.Specialties
            .AsNoTracking()
            .Where(x => x.IsActive)
            .OrderBy(x => x.Name)
            .Select(x => new SpecialtySummaryDto(x.Id, x.Name, x.IconUrl))
            .ToListAsync(cancellationToken);

        var summary = new HomeSummaryDto(
            upcomingAppointment,
            new HealthSummaryDto(records.Count, latestHeartRate?.Value, latestBloodPressure?.Value),
            topDoctors,
            specialties);

        return Ok(ApiResponse<HomeSummaryDto>.Ok(summary));
    }

    public sealed record HomeSummaryDto(
        UpcomingAppointmentDto? UpcomingAppointment,
        HealthSummaryDto HealthSummary,
        List<TopDoctorDto> TopDoctors,
        List<SpecialtySummaryDto> Specialties);

    public sealed record UpcomingAppointmentDto(
        Guid AppointmentId,
        DateTime ScheduledAt,
        string Status,
        string? LocationName,
        Guid DoctorId,
        string DoctorName,
        string Specialty);

    public sealed record HealthSummaryDto(
        int MedicalRecordsCount,
        string? LatestHeartRate,
        string? LatestBloodPressure);

    public sealed record TopDoctorDto(
        Guid DoctorId,
        string FullName,
        string Specialty,
        double Rating,
        int ReviewsCount,
        decimal ConsultationFee,
        double? Latitude,
        double? Longitude);

    public sealed record SpecialtySummaryDto(Guid Id, string Name, string? IconUrl);
}
