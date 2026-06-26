using FindYourClinic.API.Features.Specialties.CreateSpecialty;
using FindYourClinic.API.Features.Specialties.DeleteSpecialty;
using FindYourClinic.API.Features.Specialties.GetActiveSpecialties;
using FindYourClinic.API.Features.Specialties.UpdateSpecialty;
using FindYourClinic.API.Localization;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/specialties")]
public class SpecialtiesController : ControllerBase
{
    private readonly IMediator _mediator;

    public SpecialtiesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetActiveSpecialties(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetActiveSpecialtiesQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Create([FromBody] UpsertSpecialtyRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new CreateSpecialtyCommand
        {
            Name = request.Name,
            IconUrl = request.IconUrl
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpsertSpecialtyRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new UpdateSpecialtyCommand
        {
            SpecialtyId = id,
            Name = request.Name,
            IconUrl = request.IconUrl,
            IsActive = request.IsActive
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteSpecialtyCommand
        {
            SpecialtyId = id
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    public sealed class UpsertSpecialtyRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? IconUrl { get; set; }
        public bool? IsActive { get; set; }
    }
}
