using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetTopRatedDoctors;

public class GetTopRatedDoctorsQuery : IRequest<ApiResponse<CursorPaginatedResponse<TopRatedDoctorDto>>>
{
    public int? PageSize { get; set; }
    public string? Cursor { get; set; }
}
