using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Options;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace FindYourClinic.Infrastructure.Services;

public class CloudinaryService : ICloudinaryService
{
    private readonly Cloudinary _cloudinary;

    public CloudinaryService(IOptions<CloudinarySettings> settings)
    {
        var value = settings.Value;
        var account = new Account(value.CloudName, value.ApiKey, value.ApiSecret);
        _cloudinary = new Cloudinary(account);
    }

    public async Task<CloudinaryUploadResult> UploadImageAsync(IFormFile file, string folder)
    {
        await using var stream = file.OpenReadStream();
        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = folder
        };

        var result = await _cloudinary.UploadAsync(uploadParams);
        if (result.Error is not null)
        {
            throw new InvalidOperationException(result.Error.Message);
        }

        return new CloudinaryUploadResult
        {
            Url = result.SecureUrl?.ToString() ?? string.Empty,
            PublicId = result.PublicId
        };
    }

    public async Task<CloudinaryUploadResult> UploadFileAsync(IFormFile file, string folder)
    {
        await using var stream = file.OpenReadStream();
        var uploadParams = new RawUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = folder
        };

        var result = await _cloudinary.UploadAsync(uploadParams);
        if (result.Error is not null)
        {
            throw new InvalidOperationException(result.Error.Message);
        }

        return new CloudinaryUploadResult
        {
            Url = result.SecureUrl?.ToString() ?? string.Empty,
            PublicId = result.PublicId
        };
    }

    public async Task<CloudinaryVideoUploadResult> UploadVideoAsync(IFormFile file, string folder)
    {
        await using var stream = file.OpenReadStream();
        var uploadParams = new VideoUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = folder
        };

        var result = await _cloudinary.UploadAsync(uploadParams);
        if (result.Error is not null)
        {
            throw new InvalidOperationException(result.Error.Message);
        }

        var secureUrl = result.SecureUrl?.ToString() ?? string.Empty;
        string? thumbnail = null;
        if (!string.IsNullOrEmpty(result.PublicId))
        {
            // Cloudinary generates a JPG thumbnail from the first frame on demand.
            thumbnail = _cloudinary.Api.UrlImgUp
                .ResourceType("video")
                .Format("jpg")
                .BuildUrl(result.PublicId);
        }

        return new CloudinaryVideoUploadResult
        {
            Url = secureUrl,
            PublicId = result.PublicId,
            ThumbnailUrl = thumbnail,
            DurationSeconds = result.Duration > 0 ? (int)Math.Round(result.Duration) : null
        };
    }

    public async Task DeleteFileAsync(string publicId)
    {
        var result = await _cloudinary.DestroyAsync(new DeletionParams(publicId));
        if (result.Error is not null)
        {
            throw new InvalidOperationException(result.Error.Message);
        }
    }
}
