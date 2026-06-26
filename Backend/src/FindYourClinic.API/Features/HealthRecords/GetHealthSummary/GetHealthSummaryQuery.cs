using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.GetHealthSummary;

public class GetHealthSummaryQuery : IRequest<ApiResponse<HealthSummaryDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}
