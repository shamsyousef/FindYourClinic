using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.UpdateOwnDoctorProfile;

public class UpdateOwnDoctorProfileCommandHandler : IRequestHandler<UpdateOwnDoctorProfileCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;

    public UpdateOwnDoctorProfileCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result> Handle(UpdateOwnDoctorProfileCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("ONLY_DOCTORS_CAN_UPDATE_PROFILE");
        }

        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.UserId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        var specialtyExists = await _dbContext.Specialties.AnyAsync(x => x.Id == request.SpecialtyId && x.IsActive, cancellationToken);
        if (!specialtyExists)
        {
            throw new BadRequestException("INVALID_SPECIALTY");
        }

        doctorProfile.SpecialtyId = request.SpecialtyId;
        doctorProfile.ClinicName = request.ClinicName?.Trim();
        doctorProfile.ClinicAddress = request.ClinicAddress?.Trim();
        doctorProfile.Latitude = request.Latitude;
        doctorProfile.Longitude = request.Longitude;
        doctorProfile.ConsultationFee = request.ConsultationFee;
        doctorProfile.ExperienceYears = request.ExperienceYears;
        doctorProfile.Bio = request.Bio?.Trim();
        
        // Update user properties
        doctorProfile.User!.FirstName = request.FirstName.Trim();
        doctorProfile.User!.LastName = request.LastName.Trim();
        doctorProfile.User!.PhoneNumber = request.PhoneNumber?.Trim();

        await _dbContext.SaveChangesAsync(cancellationToken);
        return Result.Success("DOCTOR_PROFILE_UPDATED_SUCCESS");
    }
}
