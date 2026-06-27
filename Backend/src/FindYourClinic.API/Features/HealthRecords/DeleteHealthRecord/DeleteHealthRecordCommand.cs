using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.DeleteHealthRecord;

public class DeleteHealthRecordCommand : IRequest<ApiResponse<object>>
{
    public Guid RecordId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
