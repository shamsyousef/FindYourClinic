using System.Globalization;
using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetTopRatedDoctors;

public class GetTopRatedDoctorsQueryHandler : IRequestHandler<GetTopRatedDoctorsQuery, ApiResponse<CursorPaginatedResponse<TopRatedDoctorDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetTopRatedDoctorsQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<CursorPaginatedResponse<TopRatedDoctorDto>>> Handle(GetTopRatedDoctorsQuery query, CancellationToken cancellationToken)
    {
        var pageSize = Math.Clamp(query.PageSize ?? 10, 1, 50);
        var cursor = DecodeTopRatedCursor(query.Cursor);

        var ratingsQuery = _dbContext.DoctorReviews
            .AsNoTracking()
            .GroupBy(x => x.DoctorProfileId)
            .Select(g => new
            {
                DoctorProfileId = g.Key,
                AvgRating = g.Average(r => (double)r.Rating),
                ReviewsCount = g.Count()
            });

        var rankedQuery = from doctor in _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.Status == DoctorStatus.Approved && x.User.IsActive && x.Specialty.IsActive)
                          join rating in ratingsQuery on doctor.Id equals rating.DoctorProfileId into ratingJoin
                          from rating in ratingJoin.DefaultIfEmpty()
                          select new TopRatedDoctorProjection
                          {
                              DoctorId = doctor.UserId,
                              DoctorProfileId = doctor.Id,
                              FullName = $"{doctor.User.FirstName} {doctor.User.LastName}".Trim(),
                              Specialty = doctor.Specialty.Name,
                              ProfileImageUrl = doctor.User.ProfileImageUrl,
                              ConsultationFee = doctor.ConsultationFee,
                              Latitude = doctor.Latitude,
                              Longitude = doctor.Longitude,
                              AvgRating = rating != null ? rating.AvgRating : 0,
                              ReviewsCount = rating != null ? rating.ReviewsCount : 0
                          };

        if (cursor is not null)
        {
            var cursorRating = cursor.Value.Rating;
            var cursorDoctorId = cursor.Value.DoctorId;
            rankedQuery = rankedQuery.Where(x => x.AvgRating < cursorRating ||
                                                 (x.AvgRating == cursorRating && x.DoctorId.CompareTo(cursorDoctorId) > 0));
        }

        var page = await rankedQuery
            .OrderByDescending(x => x.AvgRating)
            .ThenBy(x => x.DoctorId)
            .Take(pageSize + 1)
            .ToListAsync(cancellationToken);

        var hasNext = page.Count > pageSize;
        if (hasNext)
        {
            page.RemoveAt(page.Count - 1);
        }

        string? nextCursor = null;
        if (hasNext && page.Count > 0)
        {
            var last = page[^1];
            nextCursor = EncodeTopRatedCursor(last.AvgRating, last.DoctorId);
        }

        var response = new CursorPaginatedResponse<TopRatedDoctorDto>(
            page.Select(x => new TopRatedDoctorDto(
                x.DoctorId,
                x.DoctorProfileId,
                x.FullName,
                x.Specialty,
                x.ProfileImageUrl,
                Math.Round(x.AvgRating, 2),
                x.ReviewsCount,
                x.ConsultationFee,
                x.Latitude,
                x.Longitude)).ToList(),
            nextCursor,
            hasNext);

        return ApiResponse<CursorPaginatedResponse<TopRatedDoctorDto>>.Ok(response);
    }

    private sealed class TopRatedDoctorProjection
    {
        public Guid DoctorId { get; set; }
        public Guid DoctorProfileId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Specialty { get; set; } = string.Empty;
        public string? ProfileImageUrl { get; set; }
        public double AvgRating { get; set; }
        public int ReviewsCount { get; set; }
        public decimal ConsultationFee { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }

    private static string EncodeTopRatedCursor(double rating, Guid doctorId)
    {
        var raw = $"{rating.ToString("R", CultureInfo.InvariantCulture)}|{doctorId:D}";
        return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(raw));
    }

    private static (double Rating, Guid DoctorId)? DecodeTopRatedCursor(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor))
        {
            return null;
        }

        try
        {
            var bytes = Convert.FromBase64String(cursor);
            var raw = System.Text.Encoding.UTF8.GetString(bytes);
            var parts = raw.Split('|', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length != 2)
            {
                return null;
            }

            if (!double.TryParse(parts[0], NumberStyles.Float, CultureInfo.InvariantCulture, out var rating))
            {
                return null;
            }

            if (!Guid.TryParse(parts[1], out var doctorId))
            {
                return null;
            }

            return (rating, doctorId);
        }
        catch
        {
            return null;
        }
    }
}
