using FindYourClinic.API.Features.Notifications.GetMyNotifications;
using FindYourClinic.API.Features.Notifications.MarkNotificationRead;
using FindYourClinic.API.Features.Notifications.RemoveDeviceToken;
using FindYourClinic.API.Features.Notifications.UpdateDeviceToken;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly IMediator _mediator;

    public NotificationsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("device-token")]
    public async Task<IActionResult> UpdateDeviceToken([FromBody] UpdateDeviceTokenCommand command)
    {
        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpDelete("device-token")]
    public async Task<IActionResult> RemoveDeviceToken()
    {
        var result = await _mediator.Send(new RemoveDeviceTokenCommand());
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetMyNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _mediator.Send(new GetMyNotificationsQuery(page, pageSize));
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPut("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead([FromRoute] Guid id)
    {
        var result = await _mediator.Send(new MarkNotificationReadCommand(id));
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
