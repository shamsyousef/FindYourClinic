using Ardalis.Result;
using FindYourClinic.API.Features.Specialties.Shared;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.CreateSpecialty;

public class CreateSpecialtyCommand : IRequest<Result<SpecialtyDto>>
{
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
}
