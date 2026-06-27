using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Auth.RefreshToken;

public class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, ApiResponse<AuthResponse>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IJwtService _jwtService;
    private readonly UserManager<Domain.Entities.ApplicationUser> _userManager;

    public RefreshTokenCommandHandler(
        ApplicationDbContext dbContext,
        IJwtService jwtService,
        UserManager<Domain.Entities.ApplicationUser> userManager)
    {
        _dbContext = dbContext;
        _jwtService = jwtService;
        _userManager = userManager;
    }

    public async Task<ApiResponse<AuthResponse>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var existing = await _dbContext.RefreshTokens
            .FirstOrDefaultAsync(x => x.Token == request.RefreshToken, cancellationToken);

        if (existing is null || existing.IsRevoked || existing.ExpiresAt <= DateTime.UtcNow)
        {
            return ApiResponse<AuthResponse>.Fail("Invalid refresh token.");
        }

        var user = await _userManager.FindByIdAsync(existing.UserId.ToString());
        if (user is null)
        {
            return ApiResponse<AuthResponse>.Fail("User not found.");
        }

        existing.IsRevoked = true;
        var newRefreshToken = _jwtService.GenerateRefreshToken(user.Id);
        _dbContext.RefreshTokens.Add(newRefreshToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var response = new AuthResponse
        {
            AccessToken = _jwtService.GenerateAccessToken(user),
            RefreshToken = newRefreshToken.Token,
            ExpiresIn = _jwtService.GetAccessTokenExpirySeconds(),
            User = new AuthUserDto
            {
                Id = user.Id,
                Email = user.Email ?? string.Empty,
                Role = user.Role.ToString(),
                FullName = $"{user.FirstName} {user.LastName}".Trim()
            }
        };

        return ApiResponse<AuthResponse>.Ok(response, "Token refreshed successfully.");
    }
}
