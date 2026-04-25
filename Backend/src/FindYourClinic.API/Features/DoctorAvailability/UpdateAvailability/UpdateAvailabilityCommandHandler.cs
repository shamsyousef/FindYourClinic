using FindYourClinic.API.Features.DoctorAvailability.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorAvailability.UpdateAvailability;

public class UpdateAvailabilityCommandHandler : IRequestHandler<UpdateAvailabilityCommand, ApiResponse<AvailabilityDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public UpdateAvailabilityCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<AvailabilityDto>> Handle(UpdateAvailabilityCommand request, CancellationToken cancellationToken)
    {
        EnsureDoctor(request.Role);

        var availability = await _dbContext.DoctorAvailabilities
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AvailabilityId, cancellationToken)
            ?? throw new NotFoundException("Availability block not found.");

        if (availability.DoctorProfile.UserId != request.UserId)
        {
            throw new ForbiddenException("You can only edit your own schedule.");
        }

        availability.DayOfWeek = request.DayOfWeek;
        availability.StartTime = request.StartTime;
        availability.EndTime = request.EndTime;
        availability.IsActive = request.IsActive;

        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<AvailabilityDto>.Ok(ToDto(availability), "Availability updated.");
    }

    private static void EnsureDoctor(UserRole role)
    {
        if (role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors can manage availability.");
        }
    }

    private static AvailabilityDto ToDto(Domain.Entities.DoctorAvailability availability)
    {
        return new AvailabilityDto(
            availability.Id,
            availability.DoctorProfileId,
            availability.DayOfWeek.ToString(),
            availability.StartTime,
            availability.EndTime,
            availability.IsActive);
    }
}
