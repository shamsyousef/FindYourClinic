using FindYourClinic.Domain.Enums;

namespace FindYourClinic.API.Features.Appointments.Shared;

public sealed record AppointmentDto(
    Guid Id,
    Guid PatientId,
    Guid DoctorProfileId,
    Guid DoctorUserId,
    DateTime ScheduledAt,
    string? LocationName,
    string Status,
    DateTime CreatedAt,
    string RelatedPersonName,
    string? RelatedPersonImageUrl,
    string? Specialty,
    string PaymentStatus,
    string? PaymentMethod,
    decimal? AmountPaid);

public static class AppointmentMappings
{
    public static AppointmentDto ToDtoProjection(
        Guid id,
        Guid patientId,
        Guid doctorProfileId,
        Guid doctorUserId,
        DateTime scheduledAt,
        string? locationName,
        AppointmentStatus status,
        DateTime createdAt,
        string personName,
        string? personImageUrl,
        string specialty,
        PaymentStatus paymentStatus,
        PaymentMethod? paymentMethod,
        decimal? amountPaid)
    {
        return new AppointmentDto(
            id, patientId, doctorProfileId, doctorUserId, scheduledAt, locationName,
            status.ToString(), createdAt, personName, personImageUrl, specialty,
            paymentStatus.ToString(),
            paymentMethod.HasValue ? paymentMethod.Value.ToString() : null,
            amountPaid);
    }
}
