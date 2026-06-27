using FindYourClinic.API.Features.Admin.GetAllTransactions;
using FindYourClinic.API.Features.Admin.GetDoctorPayouts;
using FindYourClinic.API.Features.Admin.GetFinancialStats;
using FindYourClinic.API.Features.Admin.ProcessDoctorPayout;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/admin/financial")]
[Authorize(Policy = "AdminOnly")]
public class AdminFinancialController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminFinancialController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetFinancialStatsQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null,
        [FromQuery] string? paymentMethod = null,
        CancellationToken cancellationToken = default)
    {
        var result = await _mediator.Send(new GetAllTransactionsQuery(page, pageSize, status, paymentMethod), cancellationToken);
        return Ok(result);
    }

    [HttpGet("doctors")]
    public async Task<IActionResult> GetDoctorPayouts(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorPayoutsQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpPost("doctors/{doctorProfileId:guid}/payout")]
    public async Task<IActionResult> ProcessPayout(Guid doctorProfileId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new ProcessDoctorPayoutCommand(doctorProfileId), cancellationToken);
        return Ok(result);
    }
}
