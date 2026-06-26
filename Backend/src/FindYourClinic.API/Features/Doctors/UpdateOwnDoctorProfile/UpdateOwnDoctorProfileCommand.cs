using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.UpdateOwnDoctorProfile;

public class UpdateOwnDoctorProfileCommand : IRequest<Result>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public Guid SpecialtyId { get; set; }
    public string? ClinicName { get; set; }
    public string? ClinicAddress { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public decimal ConsultationFee { get; set; }
    public int ExperienceYears { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Bio { get; set; }
}
