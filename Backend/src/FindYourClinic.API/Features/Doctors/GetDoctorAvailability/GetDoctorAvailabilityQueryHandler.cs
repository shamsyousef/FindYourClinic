using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetDoctorAvailability;

public class GetDoctorAvailabilityQueryHandler : IRequestHandler<GetDoctorAvailabilityQuery, ApiResponse<List<DateTime>>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly DoctorAvailabilitySlotsService _availabilitySlotsService;

    public GetDoctorAvailabilityQueryHandler(ApplicationDbContext dbContext, DoctorAvailabilitySlotsService availabilitySlotsService)
    {
        _dbContext = dbContext;
        _availabilitySlotsService = availabilitySlotsService;
    }

    public async Task<ApiResponse<List<DateTime>>> Handle(GetDoctorAvailabilityQuery request, CancellationToken cancellationToken)
    {
        var targetDate = request.Date ?? DateOnly.FromDateTime(DateTime.UtcNow);
        var doctorProfileId = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(x => x.UserId == request.DoctorId && x.Status == DoctorStatus.Approved)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("Doctor not found.");

        var slots = await _availabilitySlotsService.BuildAvailableSlotsAsync(doctorProfileId, targetDate, cancellationToken);
        return ApiResponse<List<DateTime>>.Ok(slots);
    }
}
