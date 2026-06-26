using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Notifications.MarkNotificationRead;

public record MarkNotificationReadCommand(Guid NotificationId) : IRequest<ApiResponse<string>>;
