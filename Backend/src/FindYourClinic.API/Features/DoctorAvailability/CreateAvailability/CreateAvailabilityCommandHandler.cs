using FindYourClinic.API.Features.DoctorAvailability.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorAvailability.CreateAvailability;

public class CreateAvailabilityCommandHandler : IRequestHandler<CreateAvailabilityCommand, ApiResponse<AvailabilityDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public CreateAvailabilityCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<AvailabilityDto>> Handle(CreateAvailabilityCommand request, CancellationToken cancellationToken)
    {
        EnsureDoctor(request.Role);

        var doctorProfileId = await _dbContext.DoctorProfiles
            .Where(x => x.UserId == request.UserId)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        var entity = new Domain.Entities.DoctorAvailability
        {
            DoctorProfileId = doctorProfileId,
            DayOfWeek = request.DayOfWeek,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            IsActive = request.IsActive
        };

        _dbContext.DoctorAvailabilities.Add(entity);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<AvailabilityDto>.Ok(ToDto(entity), "AVAILABILITY_ADDED_SUCCESS");
    }

    private static void EnsureDoctor(UserRole role)
    {
        if (role != UserRole.Doctor)
        {
            throw new ForbiddenException("ONLY_DOCTORS_CAN_MANAGE_AVAILABILITY");
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
