using FindYourClinic.API.Features.Specialties.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.GetActiveSpecialties;

public class GetActiveSpecialtiesQuery : IRequest<ApiResponse<List<SpecialtyDto>>>
{
}
