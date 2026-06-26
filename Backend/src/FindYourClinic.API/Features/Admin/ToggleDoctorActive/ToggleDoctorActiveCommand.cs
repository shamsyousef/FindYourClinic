using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.ToggleDoctorActive;

public record ToggleDoctorActiveCommand(Guid DoctorId) : IRequest<ApiResponse<ToggleDoctorActiveResult>>;

public record ToggleDoctorActiveResult(bool IsActive);
