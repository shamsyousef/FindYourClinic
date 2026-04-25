using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Models;
using FindYourClinic.Infrastructure.Options;
using Google.Apis.Auth;
using Microsoft.Extensions.Options;

namespace FindYourClinic.Infrastructure.Services;

public class GoogleAuthService : IGoogleAuthService
{
    private readonly GoogleSettings _settings;

    public GoogleAuthService(IOptions<GoogleSettings> settings)
    {
        _settings = settings.Value;
    }

    public async Task<GoogleUserInfo?> VerifyGoogleTokenAsync(string idToken)
    {
        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(idToken, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = [_settings.ClientId]
            });
        }
        catch (InvalidJwtException)
        {
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
