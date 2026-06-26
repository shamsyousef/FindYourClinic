using FindYourClinic.API.Features.DoctorAvailability.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.DoctorAvailability.GetMyAvailability;

public class GetMyAvailabilityQuery : IRequest<ApiResponse<List<AvailabilityDto>>>
{
    public Guid UserId { get; set; }
}
