using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Notifications.UpdateDeviceToken;

public record UpdateDeviceTokenCommand(string Token) : IRequest<ApiResponse<string>>;
