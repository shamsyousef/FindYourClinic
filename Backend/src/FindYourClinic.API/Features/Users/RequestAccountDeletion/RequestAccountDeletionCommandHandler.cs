using Ardalis.Result;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Users.RequestAccountDeletion;

public class RequestAccountDeletionCommandHandler : IRequestHandler<RequestAccountDeletionCommand, Result>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _dbContext;

    public RequestAccountDeletionCommandHandler(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext dbContext)
    {
        _userManager = userManager;
        _dbContext = dbContext;
    }

    public async Task<Result> Handle(RequestAccountDeletionCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByIdAsync(request.UserId.ToString());
        if (user is null)
        {
            throw new NotFoundException("USER_NOT_FOUND");
        }
        var hasPassword = await _userManager.HasPasswordAsync(user);
        if (hasPassword)
        {
            if (string.IsNullOrWhiteSpace(request.Password) || !await _userManager.CheckPasswordAsync(user, request.Password))
            {
                throw new BadRequestException("INVALID_PASSWORD_DELETION");
            }
        }

        if (user.DeletionRequestedAt.HasValue)
        {
            throw new BadRequestException("ACCOUNT_DELETION_ALREADY_REQUESTED");
        }

        user.DeletionRequestedAt = DateTime.UtcNow;
        user.IsActive = false; // Soft-disable login if you wish, or keep it true until background deletes. We'll disable it.
        
        await _dbContext.SaveChangesAsync(cancellationToken);

        return Result.Success("ACCOUNT_DELETION_REQUESTED_SUCCESS");
    }
}
