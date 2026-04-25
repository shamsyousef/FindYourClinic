using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.GetHealthRecordById;

public class GetHealthRecordByIdQuery : IRequest<ApiResponse<HealthRecordDto>>
{
    public Guid RecordId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
