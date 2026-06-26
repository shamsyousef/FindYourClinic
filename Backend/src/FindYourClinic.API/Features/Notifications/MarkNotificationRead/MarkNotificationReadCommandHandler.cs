using FindYourClinic.Domain.Common;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Notifications.MarkNotificationRead;

public class MarkNotificationReadCommandHandler : IRequestHandler<MarkNotificationReadCommand, ApiResponse<string>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public MarkNotificationReadCommandHandler(ApplicationDbContext dbContext, IHttpContextAccessor httpContextAccessor)
    {
        _dbContext = dbContext;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<ApiResponse<string>> Handle(MarkNotificationReadCommand request, CancellationToken cancellationToken)
    {
        var userIdValue = _httpContextAccessor.HttpContext?.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userIdValue) || !Guid.TryParse(userIdValue, out var userId))
        {
            return ApiResponse<string>.Fail("Unauthorized.");
        }

        var notification = await _dbContext.Notifications
            .FirstOrDefaultAsync(x => x.Id == request.NotificationId && x.UserId == userId, cancellationToken);
        if (notification is null)
        {
            return ApiResponse<string>.Fail("Notification not found.");
        }

        notification.IsRead = true;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<string>.Ok("ok", "Notification marked as read.");
    }
}
