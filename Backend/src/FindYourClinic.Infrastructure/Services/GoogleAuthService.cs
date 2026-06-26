using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Options;
using Google.Apis.Auth;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace FindYourClinic.Infrastructure.Services;

public class GoogleAuthService : IGoogleAuthService
{
    private readonly GoogleSettings _settings;
    private readonly ILogger<GoogleAuthService> _logger;

    public GoogleAuthService(IOptions<GoogleSettings> settings, ILogger<GoogleAuthService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<GoogleUserInfo?> VerifyGoogleTokenAsync(string idToken)
    {
        GoogleJsonWebSignature.Payload payload;
        try
        {
            var audiences = _settings.ClientId
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(id => id.Trim())
                .ToList();

            _logger.LogInformation("Validating Google token against {Count} audience(s): {Audiences}",
                audiences.Count, string.Join(", ", audiences));

            payload = await GoogleJsonWebSignature.ValidateAsync(idToken, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = audiences
            });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Google token validation failed: {Message}", ex.Message);
            return null;
        }

        if (payload is null || string.IsNullOrWhiteSpace(payload.Email))
        {
            return null;
        }

        return new GoogleUserInfo
        {
            Email = payload.Email,
            Name = payload.Name ?? string.Empty,
            Picture = payload.Picture
        };
    }
}
