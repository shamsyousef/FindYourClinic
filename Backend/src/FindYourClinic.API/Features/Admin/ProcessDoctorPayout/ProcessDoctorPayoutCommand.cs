using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.ProcessDoctorPayout;

public record ProcessDoctorPayoutCommand(Guid DoctorProfileId) : IRequest<ApiResponse<string>>;
