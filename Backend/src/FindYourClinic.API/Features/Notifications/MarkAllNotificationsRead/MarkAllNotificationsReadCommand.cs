using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Notifications.MarkAllNotificationsRead;

public record MarkAllNotificationsReadCommand : IRequest<ApiResponse<string>>;
