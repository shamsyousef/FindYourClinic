using FindYourClinic.API.Features.Users.GetProfile;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Users.UpdateProfile;

public class UpdateProfileCommand : IRequest<ApiResponse<UserProfileDto>>
{
    public Guid UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? BloodType { get; set; }
    public string? Address { get; set; }
    public string? EmergencyContactName { get; set; }
    public string? EmergencyContactPhone { get; set; }
}
