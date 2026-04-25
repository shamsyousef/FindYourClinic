using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.GetUsers;

public class GetUsersQueryHandler : IRequestHandler<GetUsersQuery, ApiResponse<List<UserDto>>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetUsersQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<List<UserDto>>> Handle(GetUsersQuery request, CancellationToken cancellationToken)
    {
        var users = await _dbContext.Users
            .AsNoTracking()
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email ?? string.Empty,
                FullName = $"{u.FirstName} {u.LastName}".Trim(),
                Role = u.Role.ToString(),
                IsActive = u.IsActive,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return ApiResponse<List<UserDto>>.Ok(users);
    }
}
