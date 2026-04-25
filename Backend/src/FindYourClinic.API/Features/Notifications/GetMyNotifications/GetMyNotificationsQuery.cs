using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Notifications.GetMyNotifications;

public record GetMyNotificationsQuery(int Page, int PageSize) : IRequest<ApiResponse<NotificationsPageDto>>;

public sealed record NotificationItemDto(
    Guid Id,
    string Title,
    string Body,
    string? Type,
    string? ReferenceId,
    bool IsRead,
    DateTime CreatedAt);

public sealed record NotificationsPageDto(
    List<NotificationItemDto> Items,
    int Page,
    int PageSize,
    int TotalCount);
