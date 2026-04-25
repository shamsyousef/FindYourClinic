using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Options;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace FindYourClinic.Infrastructure.Services;

public class JwtService : IJwtService
{
    private readonly JwtSettings _settings;
    private readonly byte[] _key;

    public JwtService(IOptions<JwtSettings> settings)
    {
        _settings = settings.Value;
        _key = Encoding.UTF8.GetBytes(_settings.SecretKey);
    }

    public string GenerateAccessToken(ApplicationUser user, bool isPendingDoctorToken = false)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email ?? string.Empty),
            new(ClaimTypes.Role, user.Role.ToString()),
            new("is_active", user.IsActive.ToString()),
            new("token_type", isPendingDoctorToken ? "pending_doctor" : "access")
        };

        if (!string.IsNullOrWhiteSpace(user.FirstName) || !string.IsNullOrWhiteSpace(user.LastName))
        {
            claims.Add(new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}".Trim()));
        }

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(_settings.AccessTokenExpiryMinutes),
            Issuer = _settings.Issuer,
            Audience = _settings.Audience,
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(_key), SecurityAlgorithms.HmacSha256)
        };

        var handler = new JwtSecurityTokenHandler();
        var token = handler.CreateToken(descriptor);
        return handler.WriteToken(token);
    }

    public RefreshToken GenerateRefreshToken(Guid userId)
    {
        return new RefreshToken
        {
            UserId = userId,
            Token = Convert.ToHexString(RandomNumberGenerator.GetBytes(64)),
            ExpiresAt = DateTime.UtcNow.AddDays(_settings.RefreshTokenExpiryDays)
        };
    }

    public ClaimsPrincipal? ValidateToken(string token)
    {
        var handler = new JwtSecurityTokenHandler();
        try
        {
            return handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateIssuerSigningKey = true,
                ValidateLifetime = true,
                ValidIssuer = _settings.Issuer,
                ValidAudience = _settings.Audience,
                IssuerSigningKey = new SymmetricSecurityKey(_key),
                ClockSkew = TimeSpan.Zero
            }, out _);
        }
        catch
        {
            return null;
        }
    }

    public int GetAccessTokenExpirySeconds() => _settings.AccessTokenExpiryMinutes * 60;
}
