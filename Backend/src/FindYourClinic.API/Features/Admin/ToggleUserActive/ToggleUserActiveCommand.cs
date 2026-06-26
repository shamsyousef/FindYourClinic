using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.ToggleUserActive;

public record ToggleUserActiveCommand(Guid UserId) : IRequest<ApiResponse<ToggleActiveResult>>;

public record ToggleActiveResult(bool IsActive);
