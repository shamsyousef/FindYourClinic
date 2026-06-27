using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Auth.Register;

public class RegisterCommandHandler : IRequestHandler<RegisterCommand, ApiResponse<RegisterResultDto>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _dbContext;
    private readonly IJwtService _jwtService;

    public RegisterCommandHandler(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext dbContext,
        IJwtService jwtService)
    {
        _userManager = userManager;
        _dbContext = dbContext;
        _jwtService = jwtService;
    }

    public async Task<ApiResponse<RegisterResultDto>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        if (await _userManager.FindByEmailAsync(request.Email) is not null)
        {
            return ApiResponse<RegisterResultDto>.Fail("Email is already registered.");
        }

        if (!Enum.TryParse<UserRole>(request.Role, true, out var role))
        {
            return ApiResponse<RegisterResultDto>.Fail("Invalid role.");
        }

        var user = CreateUser(request, role);
        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            return ApiResponse<RegisterResultDto>.Fail("Registration failed.", result.Errors.Select(x => x.Description).ToList());
        }

        if (role == UserRole.Doctor)
        {
            if (!request.SpecialtyId.HasValue)
            {
                return ApiResponse<RegisterResultDto>.Fail("Specialty is required for doctors.");
            }

            var specialtyExists = await _dbContext.Specialties
                .AnyAsync(x => x.Id == request.SpecialtyId.Value && x.IsActive, cancellationToken);
            if (!specialtyExists)
            {
                return ApiResponse<RegisterResultDto>.Fail("Invalid specialty.");
            }

            _dbContext.DoctorProfiles.Add(new DoctorProfile
            {
                UserId = user.Id,
                SpecialtyId = request.SpecialtyId.Value,
                Status = DoctorStatus.PendingReview
            });

            await _dbContext.SaveChangesAsync(cancellationToken);

            var pendingToken = _jwtService.GenerateAccessToken(user, isPendingDoctorToken: true);
            return ApiResponse<RegisterResultDto>.Ok(new RegisterResultDto { PendingToken = pendingToken },
                "Account pending admin review. Please upload your documents.");
        }

        var refreshToken = _jwtService.GenerateRefreshToken(user.Id);
        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var auth = new AuthResponse
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

        return ApiResponse<RegisterResultDto>.Ok(new RegisterResultDto { Auth = auth }, "Registered successfully.");
    }

    private static ApplicationUser CreateUser(RegisterCommand request, UserRole role)
    {
        var (firstName, lastName) = role == UserRole.Doctor
            ? SplitDoctorName(request.FullName ?? string.Empty)
            : (request.FirstName?.Trim() ?? string.Empty, request.LastName?.Trim() ?? string.Empty);

        return new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = request.Email.Trim().ToLowerInvariant(),
            Email = request.Email.Trim().ToLowerInvariant(),
            FirstName = firstName,
            LastName = lastName,
            Role = role,
            IsActive = role == UserRole.Patient,
            CreatedAt = DateTime.UtcNow
        };
    }

    private static (string firstName, string lastName) SplitDoctorName(string fullName)
    {
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length <= 1)
        {
            return (fullName.Trim(), string.Empty);
        }

        return (parts[0], string.Join(' ', parts.Skip(1)));
    }
}
