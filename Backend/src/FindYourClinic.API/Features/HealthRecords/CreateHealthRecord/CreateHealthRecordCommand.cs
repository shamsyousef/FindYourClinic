using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.CreateHealthRecord;

public class CreateHealthRecordCommand : IRequest<ApiResponse<HealthRecordDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public string Title { get; set; } = string.Empty;
    public HealthRecordType Type { get; set; }
    public string? Value { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? Notes { get; set; }
}
