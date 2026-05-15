using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.DeleteDoctor;

public class DeleteDoctorCommand : IRequest<ApiResponse<object>>
{
    public Guid DoctorId { get; set; }
    public string Reason { get; set; } = string.Empty;
}
