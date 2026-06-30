using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.SearchDoctors;

public class SearchDoctorsQueryHandler : IRequestHandler<SearchDoctorsQuery, ApiResponse<PaginatedResponse<DoctorSearchDto>>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly DoctorAvailabilitySlotsService _availabilitySlotsService;

    public SearchDoctorsQueryHandler(ApplicationDbContext dbContext, DoctorAvailabilitySlotsService availabilitySlotsService)
    {
        _dbContext = dbContext;
        _availabilitySlotsService = availabilitySlotsService;
    }

    public async Task<ApiResponse<PaginatedResponse<DoctorSearchDto>>> Handle(SearchDoctorsQuery query, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var page = Math.Max(1, query.Page ?? 1);
        var pageSize = Math.Clamp(query.PageSize ?? 20, 1, 100);
        var hasGeo = query.Lat.HasValue && query.Lng.HasValue;

        // ── 1. DB-translatable filters ──────────────────────────────────────
        var doctorQuery = _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.Status == DoctorStatus.Approved && x.User.IsActive && x.Specialty.IsActive);

        if (query.SpecialtyId.HasValue)
            doctorQuery = doctorQuery.Where(x => x.SpecialtyId == query.SpecialtyId.Value);
        else if (!string.IsNullOrWhiteSpace(query.SpecialtyName))
        {
            var nameLower = query.SpecialtyName.Trim().ToLower();
            doctorQuery = doctorQuery.Where(x => x.Specialty.Name.ToLower() == nameLower);
        }

        if (query.MinFee.HasValue)
            doctorQuery = doctorQuery.Where(x => x.ConsultationFee >= query.MinFee.Value);

        if (query.MaxFee.HasValue)
            doctorQuery = doctorQuery.Where(x => x.ConsultationFee <= query.MaxFee.Value);

        var projected = doctorQuery.Select(doctor => new DoctorSearchProjection
        {
            DoctorId = doctor.UserId,
            DoctorProfileId = doctor.Id,
            FullName = (doctor.User.FirstName + " " + doctor.User.LastName).Trim(),
            Specialty = doctor.Specialty.Name,
            ProfileImageUrl = doctor.User.ProfileImageUrl,
            ClinicName = doctor.ClinicName,
            ClinicAddress = doctor.ClinicAddress,
            Latitude = doctor.Latitude,
            Longitude = doctor.Longitude,
            ConsultationFee = doctor.ConsultationFee,
            ExperienceYears = doctor.ExperienceYears,
            Bio = doctor.Bio,
            AvgRating = _dbContext.DoctorReviews.Where(r => r.DoctorProfileId == doctor.Id).Average(r => (double?)r.Rating) ?? 0,
            ReviewsCount = _dbContext.DoctorReviews.Count(r => r.DoctorProfileId == doctor.Id),
            DistanceKm = null
        });

        if (query.MinRating.HasValue)
            projected = projected.Where(x => x.AvgRating >= query.MinRating.Value);

        // ── 2. Branch: needs client-side work (geo or availability) ─────────
        var hasAvailabilityFilter = !string.IsNullOrWhiteSpace(query.Availability) &&
                                    !query.Availability.Equals("anytime", StringComparison.OrdinalIgnoreCase);

        List<DoctorSearchProjection> pageItems;
        int total;

        if (hasGeo || hasAvailabilityFilter)
        {
            // Fetch all candidates into memory — haversine + availability can't run in SQL
            var all = await projected.ToListAsync(cancellationToken);

            // Compute haversine distances in memory
            if (hasGeo)
            {
                var lat = query.Lat!.Value;
                var lng = query.Lng!.Value;
                var latRad = lat * (Math.PI / 180d);
                var cosLat = Math.Cos(latRad);
                var sinLat = Math.Sin(latRad);

                foreach (var item in all)
                {
                    if (item.Latitude.HasValue && item.Longitude.HasValue)
                    {
                        var itemLatRad = item.Latitude.Value * (Math.PI / 180d);
                        var dLonRad = (item.Longitude.Value - lng) * (Math.PI / 180d);
                        item.DistanceKm = 6371d * Math.Acos(
                            Math.Min(1d, Math.Max(-1d,
                                cosLat * Math.Cos(itemLatRad) * Math.Cos(dLonRad) +
                                sinLat * Math.Sin(itemLatRad))));
                    }
                }

                if (query.RadiusKm.HasValue)
                    all = all.Where(x => x.DistanceKm.HasValue && x.DistanceKm.Value <= query.RadiusKm.Value).ToList();
            }

            // Availability filter
            var nextSlots = await _availabilitySlotsService.GetNextAvailableSlotsAsync(
                all.Select(x => x.DoctorProfileId), now, cancellationToken);
            foreach (var item in all)
                item.NextSlot = nextSlots.GetValueOrDefault(item.DoctorProfileId);

            if (hasAvailabilityFilter)
            {
                var window = DoctorAvailabilitySlotsService.GetAvailabilityWindow(query.Availability!, now);
                all = all
                    .Where(x => x.NextSlot.HasValue && x.NextSlot.Value >= window.From && x.NextSlot.Value <= window.To)
                    .ToList();
            }

            // Sort in memory
            all = query.SortBy?.ToLowerInvariant() switch
            {
                "fee_asc" => all.OrderBy(x => x.ConsultationFee).ToList(),
                "fee_desc" => all.OrderByDescending(x => x.ConsultationFee).ToList(),
                "experience" => all.OrderByDescending(x => x.ExperienceYears).ThenByDescending(x => x.AvgRating).ToList(),
                "rating" => all.OrderByDescending(x => x.AvgRating).ThenBy(x => x.ConsultationFee).ToList(),
                "distance" when hasGeo => all.OrderBy(x => x.DistanceKm ?? double.MaxValue).ToList(),
                _ => all.OrderByDescending(x => x.AvgRating).ThenBy(x => x.ConsultationFee).ToList()
            };

            total = all.Count;
            pageItems = all.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        }
        else
        {
            // ── Pure SQL path (no geo, no availability filter) ───────────────
            projected = query.SortBy?.ToLowerInvariant() switch
            {
                "fee_asc" => projected.OrderBy(x => x.ConsultationFee),
                "fee_desc" => projected.OrderByDescending(x => x.ConsultationFee),
                "experience" => projected.OrderByDescending(x => x.ExperienceYears).ThenByDescending(x => x.AvgRating),
                "rating" => projected.OrderByDescending(x => x.AvgRating).ThenBy(x => x.ConsultationFee),
                _ => projected.OrderByDescending(x => x.AvgRating).ThenBy(x => x.ConsultationFee)
            };

            total = await projected.CountAsync(cancellationToken);
            pageItems = await projected
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var nextSlots = await _availabilitySlotsService.GetNextAvailableSlotsAsync(
                pageItems.Select(x => x.DoctorProfileId), now, cancellationToken);
            foreach (var item in pageItems)
                item.NextSlot = nextSlots.GetValueOrDefault(item.DoctorProfileId);
        }

        var items = pageItems.Select(x => new DoctorSearchDto(
            x.DoctorId,
            x.DoctorProfileId,
            x.FullName,
            x.Specialty,
            x.ProfileImageUrl,
            x.ClinicName,
            x.ClinicAddress,
            x.Latitude,
            x.Longitude,
            x.ConsultationFee,
            x.ExperienceYears,
            x.Bio,
            Math.Round(x.AvgRating, 2),
            x.ReviewsCount,
            x.DistanceKm.HasValue ? Math.Round(x.DistanceKm.Value, 2) : null,
            x.NextSlot)).ToList();

        return ApiResponse<PaginatedResponse<DoctorSearchDto>>.Ok(
            new PaginatedResponse<DoctorSearchDto>(items, page, pageSize, total));
    }

    private sealed class DoctorSearchProjection
    {
        public Guid DoctorId { get; set; }
        public Guid DoctorProfileId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Specialty { get; set; } = string.Empty;
        public string? ProfileImageUrl { get; set; }
        public string? ClinicName { get; set; }
        public string? ClinicAddress { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public decimal ConsultationFee { get; set; }
        public int ExperienceYears { get; set; }
        public string? Bio { get; set; }
        public double AvgRating { get; set; }
        public int ReviewsCount { get; set; }
        public double? DistanceKm { get; set; }
        public DateTime? NextSlot { get; set; }
    }
}
