using System.Security.Cryptography;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Options;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace FindYourClinic.API.Features.Auth.ForgotPassword;

public class ForgotPasswordCommandHandler : IRequestHandler<ForgotPasswordCommand, ApiResponse<object>>
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly AppSettings _appSettings;

    public ForgotPasswordCommandHandler(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext dbContext,
        IEmailService emailService,
        IOptions<AppSettings> appSettings)
    {
        _userManager = userManager;
        _dbContext = dbContext;
        _emailService = emailService;
        _appSettings = appSettings.Value;
    }

    public async Task<ApiResponse<object>> Handle(ForgotPasswordCommand request, CancellationToken cancellationToken)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim().ToLowerInvariant());
        if (user is not null)
        {
            var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));

            _dbContext.PasswordResetTokens.Add(new PasswordResetToken
            {
                UserId = user.Id,
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddHours(1)
            });

            await _dbContext.SaveChangesAsync(cancellationToken);

            var baseUrl = _appSettings.FrontendBaseUrl.TrimEnd('/');
            var resetLink = $"{baseUrl}/reset-password?token={Uri.EscapeDataString(token)}";
            await _emailService.SendPasswordResetEmailAsync(user.Email ?? request.Email, resetLink);
        }
        Console.WriteLine("Email sent successfully");
        return ApiResponse<object>.Ok(null, "If this email exists, a password reset link has been sent.");
    }
}
