using FindYourClinic.Domain.Enums;

namespace FindYourClinic.API.Features.Appointments.Shared;

public sealed record AppointmentDto(
    Guid Id,
    Guid PatientId,
    Guid DoctorProfileId,
    DateTime ScheduledAt,
    string? LocationName,
    string Status,
    DateTime CreatedAt,
    string RelatedPersonName,
    string? Specialty);

public static class AppointmentMappings
{
    public static AppointmentDto ToDtoProjection(
        Guid id,
        Guid patientId,
        Guid doctorProfileId,
        DateTime scheduledAt,
        string? locationName,
        AppointmentStatus status,
        DateTime createdAt,
        string personName,
        string specialty)
    {
        return new AppointmentDto(id, patientId, doctorProfileId, scheduledAt, locationName, status.ToString(), createdAt, personName, specialty);
    }
}
