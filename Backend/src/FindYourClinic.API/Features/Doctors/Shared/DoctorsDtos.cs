namespace FindYourClinic.API.Features.Doctors.Shared;

public sealed record DoctorSearchDto(
    Guid DoctorId,
    Guid DoctorProfileId,
    string FullName,
    string Specialty,
    string? ProfileImageUrl,
    string? ClinicName,
    string? ClinicAddress,
    double? Latitude,
    double? Longitude,
    decimal ConsultationFee,
    int ExperienceYears,
    string? Bio,
    double AvgRating,
    int ReviewsCount,
    double? DistanceKm,
    DateTime? NextAvailableSlot);

public sealed record DoctorDetailsDto(
    Guid DoctorId,
    Guid DoctorProfileId,
    string FullName,
    string Specialty,
    string? ProfileImageUrl,
    string? ClinicName,
    string? ClinicAddress,
    double? Latitude,
    double? Longitude,
    decimal ConsultationFee,
    int ExperienceYears,
    string? Bio,
    double AvgRating,
    int ReviewsCount,
    DateTime? NextAvailableSlot);

public sealed record PaginatedResponse<T>(List<T> Items, int Page, int PageSize, int TotalCount);

public sealed record TopRatedDoctorDto(
    Guid DoctorId,
    Guid DoctorProfileId,
    string FullName,
    string Specialty,
    string? ProfileImageUrl,
    double AvgRating,
    int ReviewsCount,
    decimal ConsultationFee,
    double? Latitude,
    double? Longitude);

public sealed record CursorPaginatedResponse<T>(List<T> Items, string? NextCursor, bool HasNextPage);
