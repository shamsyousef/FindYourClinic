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

        var doctorQuery = _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.Status == DoctorStatus.Approved && x.User.IsActive && x.Specialty.IsActive);

        if (query.SpecialtyId.HasValue)
        {
            doctorQuery = doctorQuery.Where(x => x.SpecialtyId == query.SpecialtyId.Value);
        }

        if (query.MinFee.HasValue)
        {
            doctorQuery = doctorQuery.Where(x => x.ConsultationFee >= query.MinFee.Value);
        }

        if (query.MaxFee.HasValue)
        {
            doctorQuery = doctorQuery.Where(x => x.ConsultationFee <= query.MaxFee.Value);
        }

        var ratingsQuery = _dbContext.DoctorReviews
            .AsNoTracking()
            .GroupBy(x => x.DoctorProfileId)
            .Select(g => new
            {
                DoctorProfileId = g.Key,
                AvgRating = g.Average(r => (double)r.Rating),
                ReviewsCount = g.Count()
            });

        var projected = from doctor in doctorQuery
                        join rating in ratingsQuery on doctor.Id equals rating.DoctorProfileId into ratingJoin
                        from rating in ratingJoin.DefaultIfEmpty()
                        select new DoctorSearchProjection
                        {
                            DoctorId = doctor.UserId,
                            DoctorProfileId = doctor.Id,
                            FullName = $"{doctor.User.FirstName} {doctor.User.LastName}".Trim(),
                            Specialty = doctor.Specialty.Name,
                            ProfileImageUrl = doctor.User.ProfileImageUrl,
                            ClinicName = doctor.ClinicName,
                            ClinicAddress = doctor.ClinicAddress,
                            Latitude = doctor.Latitude,
                            Longitude = doctor.Longitude,
                            ConsultationFee = doctor.ConsultationFee,
                            ExperienceYears = doctor.ExperienceYears,
                            Bio = doctor.Bio,
                            AvgRating = rating != null ? rating.AvgRating : 0,
                            ReviewsCount = rating != null ? rating.ReviewsCount : 0,
                            DistanceKm = null
                        };

        if (hasGeo)
        {
            var lat = query.Lat!.Value;
            var lng = query.Lng!.Value;
            var latRad = lat * (Math.PI / 180d);

            projected = projected.Select(x => new DoctorSearchProjection
            {
                DoctorId = x.DoctorId,
                DoctorProfileId = x.DoctorProfileId,
                FullName = x.FullName,
                Specialty = x.Specialty,
                ProfileImageUrl = x.ProfileImageUrl,
                ClinicName = x.ClinicName,
                ClinicAddress = x.ClinicAddress,
                Latitude = x.Latitude,
                Longitude = x.Longitude,
                ConsultationFee = x.ConsultationFee,
                ExperienceYears = x.ExperienceYears,
                Bio = x.Bio,
                AvgRating = x.AvgRating,
                ReviewsCount = x.ReviewsCount,
                DistanceKm = x.Latitude.HasValue && x.Longitude.HasValue
                    ? 6371d * Math.Acos(
                        Math.Min(1d, Math.Max(-1d,
                            Math.Cos(latRad) * Math.Cos(x.Latitude.Value * (Math.PI / 180d)) *
                            Math.Cos((x.Longitude.Value - lng) * (Math.PI / 180d)) +
                            Math.Sin(latRad) * Math.Sin(x.Latitude.Value * (Math.PI / 180d)))))
                    : null
            });
        }

        if (query.MinRating.HasValue)
        {
            projected = projected.Where(x => x.AvgRating >= query.MinRating.Value);
        }

        if (query.RadiusKm.HasValue && hasGeo)
        {
            projected = projected.Where(x => x.DistanceKm.HasValue && x.DistanceKm.Value <= query.RadiusKm.Value);
        }

        projected = query.SortBy?.ToLowerInvariant() switch
        {
            "price" => projected.OrderBy(x => x.ConsultationFee),
            "distance" when hasGeo => projected.OrderBy(x => x.DistanceKm ?? double.MaxValue),
            _ => projected.OrderByDescending(x => x.AvgRating).ThenBy(x => x.ConsultationFee)
        };

        var hasAvailabilityFilter = !string.IsNullOrWhiteSpace(query.Availability) &&
                                    !query.Availability.Equals("anytime", StringComparison.OrdinalIgnoreCase);

        List<DoctorSearchProjection> pageItems;
        int total;

        if (hasAvailabilityFilter)
        {
            var allCandidates = await projected.ToListAsync(cancellationToken);
            var nextSlots = await _availabilitySlotsService.GetNextAvailableSlotsAsync(allCandidates.Select(x => x.DoctorProfileId), now, cancellationToken);
            foreach (var item in allCandidates)
            {
                item.NextSlot = nextSlots.GetValueOrDefault(item.DoctorProfileId);
            }

            var window = DoctorAvailabilitySlotsService.GetAvailabilityWindow(query.Availability!, now);
            var filtered = allCandidates
                .Where(x => x.NextSlot.HasValue && x.NextSlot.Value >= window.From && x.NextSlot.Value <= window.To)
                .ToList();

            total = filtered.Count;
            pageItems = filtered.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        }
        else
        {
            total = await projected.CountAsync(cancellationToken);
            pageItems = await projected
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var nextSlots = await _availabilitySlotsService.GetNextAvailableSlotsAsync(pageItems.Select(x => x.DoctorProfileId), now, cancellationToken);
            foreach (var item in pageItems)
            {
                item.NextSlot = nextSlots.GetValueOrDefault(item.DoctorProfileId);
            }
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

        var response = new PaginatedResponse<DoctorSearchDto>(items, page, pageSize, total);
        return ApiResponse<PaginatedResponse<DoctorSearchDto>>.Ok(response);
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
