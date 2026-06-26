using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Auth.ChangePassword;

public class ChangePasswordCommandHandler : IRequestHandler<ChangePasswordCommand, ApiResponse<object>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _dbContext;

    public ChangePasswordCommandHandler(UserManager<ApplicationUser> userManager, ApplicationDbContext dbContext)
    {
        _userManager = userManager;
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(ChangePasswordCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByIdAsync(request.UserId.ToString())
            ?? throw new NotFoundException("USER_NOT_FOUND");

        var passwordCorrect = await _userManager.CheckPasswordAsync(user, request.CurrentPassword);
        if (!passwordCorrect)
            throw new BadRequestException("CURRENT_PASSWORD_INCORRECT");
        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        if (!result.Succeeded)
            throw new BadRequestException("UNABLE_TO_CHANGE_PASSWORD");

        // Revoke all existing refresh tokens so other sessions are invalidated.
        var activeTokens = await _dbContext.RefreshTokens
            .Where(x => x.UserId == user.Id && !x.IsRevoked && x.ExpiresAt > DateTime.UtcNow)
            .ToListAsync(cancellationToken);

        foreach (var token in activeTokens)
            token.IsRevoked = true;

        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "PASSWORD_CHANGED_SUCCESSFULLY");
    }
}
