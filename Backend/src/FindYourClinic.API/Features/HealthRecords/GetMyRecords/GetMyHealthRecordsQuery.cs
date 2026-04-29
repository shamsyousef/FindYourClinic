using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.GetMyRecords;

public class GetMyHealthRecordsQuery : IRequest<ApiResponse<List<HealthRecordDto>>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public HealthRecordType? Type { get; set; }
}
