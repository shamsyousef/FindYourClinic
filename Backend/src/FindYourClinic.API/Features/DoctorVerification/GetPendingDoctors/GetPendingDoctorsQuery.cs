using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.DoctorVerification.GetPendingDoctors;

public record GetPendingDoctorsQuery : IRequest<ApiResponse<List<PendingDoctorDto>>>;

public class PendingDoctorDto
{
    public Guid DoctorId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty;
    public List<string> DocumentUrls { get; set; } = [];
}
