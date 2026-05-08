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
    string FirstName,
    string LastName,
    string? PhoneNumber,
    Guid SpecialtyId,
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

public sealed record DoctorDashboardDto(
    DoctorQuickStatsDto QuickStats,
    DoctorOverallStatsDto OverallStats,
    DoctorNextAppointmentDto? NextAppointment,
    DoctorPerformanceDto Performance,
    List<DoctorScheduleItemDto> TodaySchedule);

public sealed record DoctorQuickStatsDto(
    int TotalToday,
    int Completed,
    int Pending,
    int Cancelled);

public sealed record DoctorOverallStatsDto(
    int Total,
    int Completed,
    int Pending,
    int Cancelled);

public sealed record DoctorNextAppointmentDto(
    Guid AppointmentId,
    DateTime ScheduledAt,
    string Status,
    string? LocationName,
    Guid PatientId,
    string PatientName,
    string? PatientImageUrl);

public sealed record DoctorPerformanceDto(
    int TotalPatients,
    double AverageRating,
    int TotalReviews);

public sealed record DoctorScheduleItemDto(
    Guid AppointmentId,
    DateTime ScheduledAt,
    string Status,
    Guid PatientId,
    string PatientName,
    string? PatientImageUrl);
