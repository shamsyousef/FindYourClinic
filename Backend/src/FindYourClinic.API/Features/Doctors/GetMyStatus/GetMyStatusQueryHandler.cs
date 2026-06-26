using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Doctors.GetMyStatus;

public class GetMyStatusQueryHandler : IRequestHandler<GetMyStatusQuery, ApiResponse<DoctorStatusDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetMyStatusQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<DoctorStatusDto>> Handle(GetMyStatusQuery request, CancellationToken cancellationToken)
    {
        var profile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .Where(p => p.UserId == request.UserId)
            .Select(p => new
            {
                p.Status,
                p.RejectionReason,
                p.CreatedAt,
                DocumentCount = p.Documents.Count
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        return ApiResponse<DoctorStatusDto>.Ok(new DoctorStatusDto
        {
            Status = profile.Status.ToString(),
            RejectionReason = profile.RejectionReason,
            SubmittedAt = profile.CreatedAt,
            DocumentCount = profile.DocumentCount
        });
    }
}
