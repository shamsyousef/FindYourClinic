using FindYourClinic.API.Features.Specialties.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.CreateSpecialty;

public class CreateSpecialtyCommand : IRequest<ApiResponse<SpecialtyDto>>
{
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
}
