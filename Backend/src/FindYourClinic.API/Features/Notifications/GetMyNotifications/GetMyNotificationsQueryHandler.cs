using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Notifications.GetMyNotifications;

public class GetMyNotificationsQueryHandler : IRequestHandler<GetMyNotificationsQuery, ApiResponse<NotificationsPageDto>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public GetMyNotificationsQueryHandler(ApplicationDbContext dbContext, IHttpContextAccessor httpContextAccessor)
    {
        _dbContext = dbContext;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<ApiResponse<NotificationsPageDto>> Handle(GetMyNotificationsQuery request, CancellationToken cancellationToken)
    {
        var userIdValue = _httpContextAccessor.HttpContext?.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userIdValue) || !Guid.TryParse(userIdValue, out var userId))
        {
            return ApiResponse<NotificationsPageDto>.Fail("Unauthorized.");
        }

        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var query = _dbContext.Notifications
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt);

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new NotificationItemDto(
                x.Id,
                x.Title,
                x.Body,
                x.Type,
                x.ReferenceId,
                x.IsRead,
                x.CreatedAt))
            .ToListAsync(cancellationToken);

        return ApiResponse<NotificationsPageDto>.Ok(new NotificationsPageDto(items, page, pageSize, total));
    }
}
