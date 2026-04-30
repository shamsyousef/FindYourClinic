using FindYourClinic.API.Features.Admin.GetUserDocuments;
using FindYourClinic.API.Features.Admin.GetUsers;
using FindYourClinic.API.Features.Admin.ToggleUserActive;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/admin/users")]
[Authorize(Policy = "AdminOnly")]
public class AdminUsersController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminUsersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var result = await _mediator.Send(new GetUsersQuery { Page = page, PageSize = pageSize }, cancellationToken);
        return Ok(result);
    }

    [HttpPost("{userId:guid}/toggle-active")]
    public async Task<IActionResult> ToggleUserActive([FromRoute] Guid userId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new ToggleUserActiveCommand(userId), cancellationToken);
        return Ok(result);
    }

    [HttpGet("{userId:guid}/documents")]
    public async Task<IActionResult> GetUserDocuments([FromRoute] Guid userId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetUserDocumentsQuery(userId), cancellationToken);
        return Ok(result);
    }
}
