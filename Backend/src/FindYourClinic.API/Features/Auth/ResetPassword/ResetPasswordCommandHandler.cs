using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Auth.ResetPassword;

public class ResetPasswordCommandHandler : IRequestHandler<ResetPasswordCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly UserManager<ApplicationUser> _userManager;

    public ResetPasswordCommandHandler(ApplicationDbContext dbContext, UserManager<ApplicationUser> userManager)
    {
        _dbContext = dbContext;
        _userManager = userManager;
    }

    public async Task<ApiResponse<object>> Handle(ResetPasswordCommand request, CancellationToken cancellationToken)
    {
        var tokenEntity = await _dbContext.PasswordResetTokens
            .FirstOrDefaultAsync(x => x.Token == request.Token, cancellationToken);

        if (tokenEntity is null || tokenEntity.IsUsed || tokenEntity.ExpiresAt <= DateTime.UtcNow)
        {
            throw new BadRequestException("Invalid or expired reset token.");
        }

        var user = await _userManager.FindByIdAsync(tokenEntity.UserId.ToString())
            ?? throw new NotFoundException("User not found.");

        var passwordToken = await _userManager.GeneratePasswordResetTokenAsync(user);
        var resetResult = await _userManager.ResetPasswordAsync(user, passwordToken, request.NewPassword);
        if (!resetResult.Succeeded)
        {
            throw new BadRequestException("Unable to reset password.");
        }

        tokenEntity.IsUsed = true;

        var activeRefreshTokens = await _dbContext.RefreshTokens
            .Where(x => x.UserId == user.Id && !x.IsRevoked && x.ExpiresAt > DateTime.UtcNow)
            .ToListAsync(cancellationToken);

        foreach (var refreshToken in activeRefreshTokens)
        {
            refreshToken.IsRevoked = true;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "Password has been reset successfully.");
    }
}
