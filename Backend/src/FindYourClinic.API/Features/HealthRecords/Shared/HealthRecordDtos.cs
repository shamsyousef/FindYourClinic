namespace FindYourClinic.API.Features.HealthRecords.Shared;

public sealed record HealthRecordDto(
    Guid Id,
    string Title,
    string Type,
    string? Value,
    DateTime RecordedAt,
    string? Notes);

public sealed record HealthSummaryDto(
    int MedicalRecordsCount,
    string? LatestHeartRate,
    string? LatestBloodPressure,
    DateTime? LatestHeartRateAt,
    DateTime? LatestBloodPressureAt);
