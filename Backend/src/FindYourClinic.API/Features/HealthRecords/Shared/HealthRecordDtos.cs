namespace FindYourClinic.API.Features.HealthRecords.Shared;

public sealed record HealthRecordDto(
    Guid Id,
    string Title,
    string Type,
    string? Value,
    string? Unit,
    DateTime RecordedAt,
    string? Notes,
    string? FileUrl);

public sealed record HealthSummaryDto(
    int TotalRecords,
    VitalDto? BloodPressure,
    VitalDto? HeartRate,
    VitalDto? BloodSugar,
    VitalDto? Temperature,
    VitalDto? Weight,
    VitalDto? SpO2);

public sealed record VitalDto(
    string Value,
    string? Unit,
    DateTime RecordedAt);
