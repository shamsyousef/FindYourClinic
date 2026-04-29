using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.UpdateHealthRecord;

public class UpdateHealthRecordCommand : IRequest<ApiResponse<HealthRecordDto>>
{
    public Guid RecordId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public string Title { get; set; } = string.Empty;
    public HealthRecordType Type { get; set; }
    public string? Value { get; set; }
    public string? Unit { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? Notes { get; set; }
}
