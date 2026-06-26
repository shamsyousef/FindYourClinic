using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Admin.ToggleUserActive;

public class ToggleUserActiveCommandHandler : IRequestHandler<ToggleUserActiveCommand, ApiResponse<ToggleActiveResult>>
{
    private readonly ApplicationDbContext _dbContext;

    public ToggleUserActiveCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<ToggleActiveResult>> Handle(ToggleUserActiveCommand request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == request.UserId, cancellationToken)
            ?? throw new NotFoundException("USER_NOT_FOUND");

        user.IsActive = !user.IsActive;
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<ToggleActiveResult>.Ok(new ToggleActiveResult(user.IsActive));
    }
}
