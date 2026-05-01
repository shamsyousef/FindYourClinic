using FindYourClinic.API.Features.Users.GetProfile;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Users.GetPatientProfileForDoctor;

public class GetPatientProfileForDoctorQuery : IRequest<ApiResponse<UserProfileDto>>
{
    public Guid DoctorUserId { get; set; }
    public UserRole Role { get; set; }
    public Guid PatientId { get; set; }
}
