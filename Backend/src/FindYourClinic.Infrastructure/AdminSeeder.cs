using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Options;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.Infrastructure;

public static class AdminSeeder
{
    public static async Task SeedAdminAsync(this IServiceProvider serviceProvider, IConfiguration configuration)
    {
        var settings = configuration.GetSection("AdminSeed").Get<AdminSeedSettings>() ?? new AdminSeedSettings();
        if (!settings.Enabled)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(settings.Email) || string.IsNullOrWhiteSpace(settings.Password))
        {
            var logger = serviceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("AdminSeeder");
            logger.LogWarning("Admin seeding is enabled but email/password are missing.");
            return;
        }

        var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var normalizedEmail = settings.Email.Trim().ToLowerInvariant();
        var existing = await userManager.FindByEmailAsync(normalizedEmail);
        if (existing is not null)
        {
            if (existing.Role != UserRole.Admin || !existing.IsActive)
            {
                existing.Role = UserRole.Admin;
                existing.IsActive = true;
                await userManager.UpdateAsync(existing);
            }

            return;
        }

        var admin = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = normalizedEmail,
            Email = normalizedEmail,
            FirstName = settings.FirstName.Trim(),
            LastName = settings.LastName.Trim(),
            Role = UserRole.Admin,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var createResult = await userManager.CreateAsync(admin, settings.Password);
        if (!createResult.Succeeded)
        {
            var errors = string.Join(", ", createResult.Errors.Select(x => x.Description));
            throw new InvalidOperationException($"Unable to seed admin user. Errors: {errors}");
        }
    }
}
