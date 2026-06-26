using FindYourClinic.API.Features.Specialties.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.GetActiveSpecialties;

public class GetActiveSpecialtiesQueryHandler : IRequestHandler<GetActiveSpecialtiesQuery, ApiResponse<List<SpecialtyDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetActiveSpecialtiesQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<SpecialtyDto>>> Handle(GetActiveSpecialtiesQuery request, CancellationToken cancellationToken)
    {
        var specialties = await _dbContext.Specialties
            .AsNoTracking()
            .Where(x => x.IsActive)
            .OrderBy(x => x.Name)
            .Select(x => new SpecialtyDto(x.Id, x.Name, x.IconUrl))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<SpecialtyDto>>.Ok(specialties);
    }
}
