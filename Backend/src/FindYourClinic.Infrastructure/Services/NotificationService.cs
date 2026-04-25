using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(ApplicationDbContext context, ILogger<NotificationService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .Where(u => u.Id == userId && u.FcmToken != null)
            .Select(u => new { u.FcmToken })
            .FirstOrDefaultAsync(cancellationToken);

        if (user?.FcmToken is not null)
        {
            await SendToTokenAsync(user.FcmToken, title, body, data, cancellationToken);
        }
        else
        {
            _logger.LogWarning("No FCM token found for user {UserId}", userId);
        }

        await SaveNotificationAsync(userId, title, body, data, cancellationToken);
    }

    public async Task SendToTokenAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        if (FirebaseApp.DefaultInstance is null)
        {
            _logger.LogWarning("Firebase is not initialized. Push notification skipped.");
            return;
        }

        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data ?? new Dictionary<string, string>(),
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        Sound = "default"
                    }
                },
                Apns = new ApnsConfig
                {
                    Aps = new Aps
                    {
                        Sound = "default",
                        Badge = 1
                    }
                }
            };

            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
            _logger.LogInformation("FCM notification sent. MessageId: {MessageId}", response);
        }
        catch (FirebaseMessagingException ex)
            when (ex.MessagingErrorCode == MessagingErrorCode.Unregistered ||
                  ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument)
        {
            _logger.LogWarning("Stale FCM token detected and removed. Error: {Error}", ex.Message);
            await RemoveStaleTokenAsync(fcmToken, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM notification.");
        }
    }

    public async Task SendToMultipleAsync(
        IEnumerable<string> fcmTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        if (FirebaseApp.DefaultInstance is null)
        {
            _logger.LogWarning("Firebase is not initialized. Multicast notification skipped.");
            return;
        }

        var tokenList = fcmTokens.Where(x => !string.IsNullOrWhiteSpace(x)).Distinct().ToList();
        if (tokenList.Count == 0)
        {
            return;
        }

        var message = new MulticastMessage
        {
            Tokens = tokenList,
            Notification = new FirebaseAdmin.Messaging.Notification
            {
                Title = title,
                Body = body
            },
            Data = data ?? new Dictionary<string, string>()
        };

        var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message, cancellationToken);
        _logger.LogInformation("Multicast sent. Success: {SuccessCount}, Failure: {FailureCount}", response.SuccessCount, response.FailureCount);
    }

    private async Task SaveNotificationAsync(
        Guid userId,
        string title,
        string body,
        Dictionary<string, string>? data,
        CancellationToken cancellationToken)
    {
        _context.Notifications.Add(new Domain.Entities.Notification
        {
            UserId = userId,
            Title = title,
            Body = body,
            Type = data?.GetValueOrDefault("type"),
            ReferenceId = data?.GetValueOrDefault("referenceId"),
            IsRead = false
        });

        await _context.SaveChangesAsync(cancellationToken);
    }

    private async Task RemoveStaleTokenAsync(string token, CancellationToken cancellationToken)
    {
        var user = await _context.Users.FirstOrDefaultAsync(x => x.FcmToken == token, cancellationToken);
        if (user is null)
        {
            return;
        }

        user.FcmToken = null;
        user.FcmTokenUpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(cancellationToken);
    }
}
