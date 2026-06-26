using FindYourClinic.API.Features.DoctorAvailability.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.DoctorAvailability.GetMyAvailability;

public class GetMyAvailabilityQueryHandler : IRequestHandler<GetMyAvailabilityQuery, ApiResponse<List<AvailabilityDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetMyAvailabilityQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<AvailabilityDto>>> Handle(GetMyAvailabilityQuery request, CancellationToken cancellationToken)
    {
        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == request.UserId && x.Status == DoctorStatus.Approved, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        var availabilities = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .Where(x => x.DoctorProfileId == doctorProfile.Id && x.IsActive)
            .OrderBy(x => x.DayOfWeek)
            .ThenBy(x => x.StartTime)
            .Select(x => new AvailabilityDto(
                x.Id,
                x.DoctorProfileId,
                x.DayOfWeek.ToString(),
                x.StartTime,
                x.EndTime,
                x.IsActive))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<AvailabilityDto>>.Ok(availabilities);
    }
}
