using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Auth.GoogleLogin;

public class GoogleLoginCommandHandler : IRequestHandler<GoogleLoginCommand, ApiResponse<GoogleLoginResultDto>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IGoogleAuthService _googleAuthService;
    private readonly ICloudinaryService _cloudinaryService;
    private readonly IJwtService _jwtService;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpClientFactory _httpClientFactory;

    public GoogleLoginCommandHandler(
        UserManager<ApplicationUser> userManager,
        IGoogleAuthService googleAuthService,
        ICloudinaryService cloudinaryService,
        IJwtService jwtService,
        ApplicationDbContext dbContext,
        IHttpClientFactory httpClientFactory)
    {
        _userManager = userManager;
        _googleAuthService = googleAuthService;
        _cloudinaryService = cloudinaryService;
        _jwtService = jwtService;
        _dbContext = dbContext;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<ApiResponse<GoogleLoginResultDto>> Handle(GoogleLoginCommand request, CancellationToken cancellationToken)
    {
        var googleUser = await _googleAuthService.VerifyGoogleTokenAsync(request.IdToken);
        if (googleUser is null)
        {
            return ApiResponse<GoogleLoginResultDto>.Fail("Invalid Google token.");
        }

        var email = googleUser.Email.Trim().ToLowerInvariant();
        var user = await _userManager.Users.FirstOrDefaultAsync(x => x.Email == email, cancellationToken);

        if (user is null)
        {
            if (string.IsNullOrWhiteSpace(request.Role) || !Enum.TryParse<UserRole>(request.Role, true, out var role))
            {
                return ApiResponse<GoogleLoginResultDto>.Fail("Role is required for first-time Google login.");
            }

            user = await CreateGoogleUserAsync(googleUser, role, cancellationToken);
        }

        if (user.Role == UserRole.Doctor && !user.IsActive)
        {
            var pendingToken = _jwtService.GenerateAccessToken(user, isPendingDoctorToken: true);
            return ApiResponse<GoogleLoginResultDto>.Ok(
                new GoogleLoginResultDto { PendingToken = pendingToken },
                "Your account is under review. You will be notified once approved (24-48 hours).");
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

        return ApiResponse<GoogleLoginResultDto>.Ok(new GoogleLoginResultDto { Auth = auth }, "Google login successful.");
    }

    private async Task<ApplicationUser> CreateGoogleUserAsync(
        GoogleUserInfo googleUser,
        UserRole role,
        CancellationToken cancellationToken)
    {
        var user = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = googleUser.Email.Trim().ToLowerInvariant(),
            Email = googleUser.Email.Trim().ToLowerInvariant(),
            Role = role,
            IsActive = role == UserRole.Patient
        };

        var nameParts = googleUser.Name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        user.FirstName = nameParts.FirstOrDefault() ?? string.Empty;
        user.LastName = nameParts.Length > 1 ? string.Join(' ', nameParts.Skip(1)) : string.Empty;

        var result = await _userManager.CreateAsync(user);
        if (!result.Succeeded)
        {
            throw new InvalidOperationException("Google registration failed.");
        }

        if (!string.IsNullOrWhiteSpace(googleUser.Picture))
        {
            var profileUpload = await UploadGoogleProfilePictureAsync(googleUser.Picture, user.Id);
            user.ProfileImageUrl = profileUpload.Url;
            user.CloudinaryPublicId = profileUpload.PublicId;
            await _userManager.UpdateAsync(user);
        }

        if (role == UserRole.Doctor)
        {
            var defaultSpecialty = await _dbContext.Specialties.FirstOrDefaultAsync(x => x.IsActive, cancellationToken);
            if (defaultSpecialty is null)
            {
                defaultSpecialty = new Specialty
                {
                    Name = "General",
                    IsActive = true
                };
                _dbContext.Specialties.Add(defaultSpecialty);
                await _dbContext.SaveChangesAsync(cancellationToken);
            }

            _dbContext.DoctorProfiles.Add(new DoctorProfile
            {
                UserId = user.Id,
                SpecialtyId = defaultSpecialty.Id,
                Status = DoctorStatus.PendingReview
            });
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return user;
    }

    private async Task<CloudinaryUploadResult> UploadGoogleProfilePictureAsync(string pictureUrl, Guid userId)
    {
        var client = _httpClientFactory.CreateClient();
        var bytes = await client.GetByteArrayAsync(pictureUrl);
        await using var stream = new MemoryStream(bytes);
        var formFile = new FormFile(stream, 0, stream.Length, "file", $"google-{userId}.jpg")
        {
            Headers = new HeaderDictionary(),
            ContentType = "image/jpeg"
        };

        return await _cloudinaryService.UploadImageAsync(formFile, $"clinic/users/{userId}");
    }
}
