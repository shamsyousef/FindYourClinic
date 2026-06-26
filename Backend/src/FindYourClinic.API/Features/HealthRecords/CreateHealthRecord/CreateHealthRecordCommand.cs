using Ardalis.Result;
using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Http;

namespace FindYourClinic.API.Features.HealthRecords.CreateHealthRecord;

public class CreateHealthRecordCommand : IRequest<Result<HealthRecordDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public string Title { get; set; } = string.Empty;
    public HealthRecordType Type { get; set; }
    public string? Value { get; set; }
    public string? Unit { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? Notes { get; set; }
    public IFormFile? Attachment { get; set; }
}
