using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;


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
            return ApiResponse<AuthResponse>.Fail("INVALID_EMAIL_OR_PASSWORD");
        }

        if (user.DeletionRequestedAt.HasValue)
        {
            throw new ForbiddenException("YOUR_ACCOUNT_IS_SCHEDULED_FOR_DELETION");
        }

        if (user.Role == UserRole.Doctor && !user.IsActive)
        {
            var doctorProfile = await _dbContext.DoctorProfiles
                .FirstOrDefaultAsync(p => p.UserId == user.Id, cancellationToken);

            if (doctorProfile?.Status == DoctorStatus.Rejected)
            {
                throw new ForbiddenException("YOUR_ACCOUNT_HAS_BEEN_REJECTED");
            }

            throw new ForbiddenException("YOUR_ACCOUNT_IS_UNDER_REVIEW");
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

        return ApiResponse<AuthResponse>.Ok(response, "LOGIN_SUCCESSFUL");
    }
}
