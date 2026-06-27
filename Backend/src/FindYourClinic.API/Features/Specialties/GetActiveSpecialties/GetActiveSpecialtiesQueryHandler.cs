using FindYourClinic.API.Features.Specialties.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;

namespace FindYourClinic.API.Features.Specialties.GetActiveSpecialties;

public class GetActiveSpecialtiesQueryHandler : IRequestHandler<GetActiveSpecialtiesQuery, ApiResponse<List<SpecialtyDto>>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public GetActiveSpecialtiesQueryHandler(ApplicationDbContext dbContext, IHttpContextAccessor httpContextAccessor)
    {
        _dbContext = dbContext;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<ApiResponse<List<SpecialtyDto>>> Handle(GetActiveSpecialtiesQuery request, CancellationToken cancellationToken)
    {
        var lang = _httpContextAccessor.HttpContext?.Request.Headers["Accept-Language"].ToString();
        bool isArabic = !string.IsNullOrEmpty(lang) && lang.StartsWith("ar", StringComparison.OrdinalIgnoreCase);

        var specialties = await _dbContext.Specialties
            .AsNoTracking()
            .Where(x => x.IsActive)
            .OrderBy(x => x.Name)
            .Select(x => new SpecialtyDto(x.Id, isArabic && !string.IsNullOrEmpty(x.NameAr) ? x.NameAr : x.Name, x.IconUrl))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<SpecialtyDto>>.Ok(specialties);
    }
}
