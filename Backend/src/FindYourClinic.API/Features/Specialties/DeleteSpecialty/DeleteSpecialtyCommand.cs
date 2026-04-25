using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.DeleteSpecialty;

public class DeleteSpecialtyCommand : IRequest<ApiResponse<object>>
{
    public Guid SpecialtyId { get; set; }
}
