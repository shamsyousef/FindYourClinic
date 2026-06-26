using FindYourClinic.Domain.Enums;

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
public sealed class CreateHealthRecordRequest
{
    public string Title { get; set; } = string.Empty;
    public HealthRecordType Type { get; set; }
    public string? Value { get; set; }
    public string? Unit { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? Notes { get; set; }
    public IFormFile? Attachment { get; set; }
}

public sealed class UpdateHealthRecordRequest
{
    public string Title { get; set; } = string.Empty;
    public HealthRecordType Type { get; set; }
    public string? Value { get; set; }
    public string? Unit { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? Notes { get; set; }

}