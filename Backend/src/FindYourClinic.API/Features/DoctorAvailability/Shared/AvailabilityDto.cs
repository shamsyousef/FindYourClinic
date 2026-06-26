namespace FindYourClinic.API.Features.DoctorAvailability.Shared;

public sealed record AvailabilityDto(
    Guid Id,
    Guid DoctorProfileId,
    string DayOfWeek,
    TimeSpan StartTime,
    TimeSpan EndTime,
    bool IsActive);
