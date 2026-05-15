using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Users.RequestAccountDeletion;

public class RequestAccountDeletionCommandHandler : IRequestHandler<RequestAccountDeletionCommand, ApiResponse<object>>
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

    public async Task<ApiResponse<object>> Handle(RequestAccountDeletionCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByIdAsync(request.UserId.ToString());
        if (user is null)
        {
            throw new NotFoundException("User not found.");
        }

        if (!await _userManager.CheckPasswordAsync(user, request.Password))
        {
            throw new BadRequestException("Invalid password. Please enter your correct password to request account deletion.");
        }

        if (user.DeletionRequestedAt.HasValue)
        {
            throw new BadRequestException("Account deletion is already requested.");
        }

        user.DeletionRequestedAt = DateTime.UtcNow;
        user.IsActive = false; // Soft-disable login if you wish, or keep it true until background deletes. We'll disable it.
        
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<object>.Ok(null, "Account deletion requested successfully. Your account will be permanently deleted in 30 days.");
    }
}
