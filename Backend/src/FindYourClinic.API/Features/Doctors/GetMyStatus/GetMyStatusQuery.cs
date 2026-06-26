using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetMyStatus;

public class GetMyStatusQuery : IRequest<ApiResponse<DoctorStatusDto>>
{
    public Guid UserId { get; set; }
}

public class DoctorStatusDto
{
    public string Status { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public int DocumentCount { get; set; }
}
