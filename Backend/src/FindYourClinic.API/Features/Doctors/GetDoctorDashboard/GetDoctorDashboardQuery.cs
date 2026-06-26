using FindYourClinic.API.Features.Doctors.Shared;
using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetDoctorDashboard;

public class GetDoctorDashboardQuery : IRequest<ApiResponse<DoctorDashboardDto>>
{
    public Guid UserId { get; set; }
}
