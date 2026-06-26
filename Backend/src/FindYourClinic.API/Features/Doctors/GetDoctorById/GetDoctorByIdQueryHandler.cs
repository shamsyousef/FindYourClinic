using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetDoctorById;

public class GetDoctorByIdQueryHandler : IRequestHandler<GetDoctorByIdQuery, ApiResponse<DoctorDetailsDto>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly DoctorAvailabilitySlotsService _availabilitySlotsService;

    public GetDoctorByIdQueryHandler(ApplicationDbContext dbContext, DoctorAvailabilitySlotsService availabilitySlotsService)
    {
        _dbContext = dbContext;
        _availabilitySlotsService = availabilitySlotsService;
    }

    public async Task<ApiResponse<DoctorDetailsDto>> Handle(GetDoctorByIdQuery request, CancellationToken cancellationToken)
    {
        var doctor = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.UserId == request.DoctorId && x.Status == DoctorStatus.Approved && x.User.IsActive)
            .Select(x => new
            {
                DoctorId = x.UserId,
                DoctorProfileId = x.Id,
                FullName = $"{x.User.FirstName} {x.User.LastName}".Trim(),
                FirstName = x.User.FirstName,
                LastName = x.User.LastName,
                PhoneNumber = x.User.PhoneNumber,
                SpecialtyId = x.SpecialtyId,
                Specialty = x.Specialty.Name,
                ProfileImageUrl = x.User.ProfileImageUrl,
                ConsultationFee = x.ConsultationFee,
                ClinicName = x.ClinicName,
                ClinicAddress = x.ClinicAddress,
                Latitude = x.Latitude,
                Longitude = x.Longitude,
                ExperienceYears = x.ExperienceYears,
                Bio = x.Bio,
                AvgRating = _dbContext.DoctorReviews.Where(r => r.DoctorProfileId == x.Id).Select(r => (double?)r.Rating).Average() ?? 0,
                ReviewsCount = _dbContext.DoctorReviews.Count(r => r.DoctorProfileId == x.Id)
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("DOCTOR_NOT_FOUND");

        var nextSlot = await _availabilitySlotsService.GetNextAvailableSlotAsync(doctor.DoctorProfileId, DateTime.UtcNow, cancellationToken);
        var dto = new DoctorDetailsDto(
            doctor.DoctorId,
            doctor.DoctorProfileId,
            doctor.FullName,
            doctor.FirstName,
            doctor.LastName,
            doctor.PhoneNumber,
            doctor.SpecialtyId,
            doctor.Specialty,
            doctor.ProfileImageUrl,
            doctor.ClinicName,
            doctor.ClinicAddress,
            doctor.Latitude,
            doctor.Longitude,
            doctor.ConsultationFee,
            doctor.ExperienceYears,
            doctor.Bio,
            Math.Round(doctor.AvgRating, 2),
            doctor.ReviewsCount,
            nextSlot);

        return ApiResponse<DoctorDetailsDto>.Ok(dto);
    }
}
