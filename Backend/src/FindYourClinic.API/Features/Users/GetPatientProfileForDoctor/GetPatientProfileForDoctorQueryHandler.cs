using FindYourClinic.API.Features.Users.GetProfile;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Users.GetPatientProfileForDoctor;

public class GetPatientProfileForDoctorQueryHandler
    : IRequestHandler<GetPatientProfileForDoctorQuery, ApiResponse<UserProfileDto>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly UserManager<Domain.Entities.ApplicationUser> _userManager;

    public GetPatientProfileForDoctorQueryHandler(
        ApplicationDbContext dbContext,
        UserManager<Domain.Entities.ApplicationUser> userManager)
    {
        _dbContext = dbContext;
        _userManager = userManager;
    }

    public async Task<ApiResponse<UserProfileDto>> Handle(
        GetPatientProfileForDoctorQuery request,
        CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("Only doctors can view patient profiles.");

        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(dp => dp.UserId == request.DoctorUserId, cancellationToken)
            ?? throw new NotFoundException("Doctor profile not found.");

        var hasRelationship = await _dbContext.Appointments
            .AnyAsync(
                a => a.DoctorProfileId == doctorProfile.Id && a.PatientId == request.PatientId,
                cancellationToken);

        if (!hasRelationship)
            throw new ForbiddenException("You can only view profiles of patients you have appointments with.");

        var patient = await _userManager.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == request.PatientId, cancellationToken)
            ?? throw new NotFoundException("Patient not found.");

        return ApiResponse<UserProfileDto>.Ok(new UserProfileDto
        {
            Id = patient.Id,
            Email = patient.Email ?? string.Empty,
            FirstName = patient.FirstName,
            LastName = patient.LastName,
            Role = patient.Role.ToString(),
            ProfileImageUrl = patient.ProfileImageUrl,
            PhoneNumber = patient.PhoneNumber,
            DateOfBirth = patient.DateOfBirth,
            Gender = patient.Gender,
            BloodType = patient.BloodType,
            Address = patient.Address,
            EmergencyContactName = patient.EmergencyContactName,
            EmergencyContactPhone = patient.EmergencyContactPhone,
        });
    }
}
