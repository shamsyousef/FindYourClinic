using FindYourClinic.Domain.Entities;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.API.Services;

public class AccountCleanupBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AccountCleanupBackgroundService> _logger;

    public AccountCleanupBackgroundService(
        IServiceProvider serviceProvider,
        ILogger<AccountCleanupBackgroundService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AccountCleanupBackgroundService started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CleanupAccountsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while cleaning up accounts.");
            }

            // Run once a day
            await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
        }
    }

    private async Task CleanupAccountsAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        // Find users who requested deletion more than 30 days ago
        var cutoffDate = DateTime.UtcNow.AddDays(-30);
        
        var usersToDelete = await dbContext.Users
            .Where(u => u.DeletionRequestedAt != null && u.DeletionRequestedAt <= cutoffDate)
            .ToListAsync(cancellationToken);

        if (!usersToDelete.Any())
        {
            return;
        }

        _logger.LogInformation("Found {Count} accounts to permanently delete.", usersToDelete.Count);

        foreach (var user in usersToDelete)
        {
            try
            {
                // Cascade delete will remove appointments, reviews, records, chats, etc.
                var result = await userManager.DeleteAsync(user);
                if (result.Succeeded)
                {
                    _logger.LogInformation("Successfully deleted user {UserId}.", user.Id);
                }
                else
                {
                    _logger.LogWarning("Failed to delete user {UserId}. Errors: {Errors}", user.Id, string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception while deleting user {UserId}", user.Id);
            }
        }
    }
}
