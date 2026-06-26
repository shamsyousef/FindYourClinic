using Ardalis.Result;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.UpdateSpecialty;

public class UpdateSpecialtyCommand : IRequest<Result<Guid>>
{
    public Guid SpecialtyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
    public bool? IsActive { get; set; }
}
