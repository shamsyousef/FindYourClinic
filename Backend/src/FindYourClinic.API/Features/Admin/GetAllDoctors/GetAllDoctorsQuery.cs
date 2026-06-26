using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Admin.GetAllDoctors;

public record GetAllDoctorsQuery(DoctorStatus? Status) : IRequest<ApiResponse<List<AllDoctorDto>>>;

public class AllDoctorDto
{
    public Guid DoctorId { get; set; }
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public string? RejectionReason { get; set; }
    public List<string> DocumentUrls { get; set; } = [];
}
