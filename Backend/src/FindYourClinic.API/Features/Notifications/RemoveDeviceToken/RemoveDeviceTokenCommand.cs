using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Notifications.RemoveDeviceToken;

public record RemoveDeviceTokenCommand : IRequest<ApiResponse<string>>;
