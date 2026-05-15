using System.Security.Claims;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Models;
using Microsoft.AspNetCore.Http;

namespace FindYourClinic.Domain.Interfaces;

public interface ICloudinaryService
{
    Task<CloudinaryUploadResult> UploadImageAsync(IFormFile file, string folder);
    Task<CloudinaryUploadResult> UploadFileAsync(IFormFile file, string folder);
    Task<CloudinaryVideoUploadResult> UploadVideoAsync(IFormFile file, string folder);
    Task DeleteFileAsync(string publicId);
}

public interface IJwtService
{
    string GenerateAccessToken(ApplicationUser user, bool isPendingDoctorToken = false);
    RefreshToken GenerateRefreshToken(Guid userId);
    ClaimsPrincipal? ValidateToken(string token);
    int GetAccessTokenExpirySeconds();
}

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(string toEmail, string resetLink);
    Task SendDoctorApprovedEmailAsync(string toEmail, string doctorName);
    Task SendDoctorRejectedEmailAsync(string toEmail, string doctorName, string reason);
    Task SendDoctorActivatedEmailAsync(string toEmail, string doctorName);
    Task SendDoctorDeactivatedEmailAsync(string toEmail, string doctorName);
    Task SendDoctorDeletedEmailAsync(string toEmail, string doctorName, string reason);
}

public interface IGoogleAuthService
{
    Task<GoogleUserInfo?> VerifyGoogleTokenAsync(string idToken);
}
