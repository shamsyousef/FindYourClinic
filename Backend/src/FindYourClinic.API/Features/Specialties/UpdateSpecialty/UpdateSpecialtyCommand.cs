using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.UpdateSpecialty;

public class UpdateSpecialtyCommand : IRequest<ApiResponse<object>>
{
    public Guid SpecialtyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
    public bool? IsActive { get; set; }
}
