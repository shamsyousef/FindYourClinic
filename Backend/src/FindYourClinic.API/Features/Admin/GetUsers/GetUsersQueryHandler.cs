using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetUsers;

public class GetUsersQueryHandler : IRequestHandler<GetUsersQuery, ApiResponse<PagedUsersDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetUsersQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<PagedUsersDto>> Handle(GetUsersQuery request, CancellationToken cancellationToken)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize, 1, 1000);

        var query = _dbContext.Users
            .AsNoTracking()
            .OrderByDescending(u => u.CreatedAt);

        var totalCount = await query.CountAsync(cancellationToken);

        var users = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email ?? string.Empty,
                FullName = $"{u.FirstName} {u.LastName}".Trim(),
                Role = u.Role.ToString(),
                IsActive = u.IsActive,
                CreatedAt = u.CreatedAt,
                DoctorId = u.Role == UserRole.Doctor ? u.Id : (Guid?)null
            })
            .ToListAsync(cancellationToken);

        return ApiResponse<PagedUsersDto>.Ok(new PagedUsersDto(users, page, pageSize, totalCount));
    }
}
