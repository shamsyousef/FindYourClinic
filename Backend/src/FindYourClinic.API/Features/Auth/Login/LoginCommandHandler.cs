using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.API.Features.Auth.Login;

public class LoginCommandHandler : IRequestHandler<LoginCommand, ApiResponse<AuthResponse>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IJwtService _jwtService;
    private readonly ApplicationDbContext _dbContext;

    public LoginCommandHandler(
        UserManager<ApplicationUser> userManager,
        IJwtService jwtService,
        ApplicationDbContext dbContext)
    {
        _userManager = userManager;
        _jwtService = jwtService;
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<AuthResponse>> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim().ToLowerInvariant());
        if (user is null || !await _userManager.CheckPasswordAsync(user, request.Password))
        {
            return ApiResponse<AuthResponse>.Fail("Invalid email or password.");
        }

        if (user.Role == UserRole.Doctor && !user.IsActive)
        {
            throw new ForbiddenException("Your account is under review. You will be notified once approved (24-48 hours).");
        }

        var refreshToken = _jwtService.GenerateRefreshToken(user.Id);
        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var response = new AuthResponse
        {
            AccessToken = _jwtService.GenerateAccessToken(user),
            RefreshToken = refreshToken.Token,
            ExpiresIn = _jwtService.GetAccessTokenExpirySeconds(),
            User = new AuthUserDto
            {
                Id = user.Id,
                Email = user.Email ?? string.Empty,
                Role = user.Role.ToString(),
                FullName = $"{user.FirstName} {user.LastName}".Trim()
            }
        };

        return ApiResponse<AuthResponse>.Ok(response, "Logged in successfully.");
    }
}
