namespace FindYourClinic.Domain.Services;

public interface INotificationService
{
    Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);

    Task SendToTokenAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);

    Task SendToMultipleAsync(
        IEnumerable<string> fcmTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);
}
