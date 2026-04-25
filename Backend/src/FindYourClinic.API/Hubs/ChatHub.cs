using FindYourClinic.API.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public ChatHub(ApplicationDbContext dbContext, INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task JoinConversation(Guid conversationId)
    {
        var (userId, conversation) = await GetAuthorizedConversationAsync(conversationId, Context.ConnectionAborted);
        _ = userId;
        await Groups.AddToGroupAsync(Context.ConnectionId, GetConversationGroup(conversationId), Context.ConnectionAborted);
    }

    public async Task LeaveConversation(Guid conversationId)
    {
        var (userId, conversation) = await GetAuthorizedConversationAsync(conversationId, Context.ConnectionAborted);
        _ = userId;
        _ = conversation;
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetConversationGroup(conversationId), Context.ConnectionAborted);
    }

    public async Task SendMessage(Guid conversationId, string content)
    {
        var (userId, conversation) = await GetAuthorizedConversationAsync(conversationId, Context.ConnectionAborted);

        if (string.IsNullOrWhiteSpace(content))
        {
            throw new BadRequestException("Message content is required.");
        }

        var trimmed = content.Trim();
        var now = DateTime.UtcNow;
        var message = new ChatMessage
        {
            ConversationId = conversationId,
            SenderId = userId,
            Content = trimmed,
            SentAt = now,
            IsRead = false
        };

        conversation.LastMessageAt = now;
        _dbContext.ChatMessages.Add(message);
        await _dbContext.SaveChangesAsync(Context.ConnectionAborted);

        var senderName = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => $"{x.FirstName} {x.LastName}".Trim())
            .FirstOrDefaultAsync(Context.ConnectionAborted) ?? "Someone";

        var receiverId = conversation.PatientId == userId ? conversation.DoctorId : conversation.PatientId;
        var eventPayload = new RealtimeMessageDto(
            message.Id,
            message.ConversationId,
            message.SenderId,
            senderName,
            message.Content,
            message.SentAt,
            message.IsRead);

        await Clients.Group(GetConversationGroup(conversationId)).SendAsync("messageReceived", eventPayload, Context.ConnectionAborted);
        await Clients.User(receiverId.ToString()).SendAsync("conversationUpdated", new ConversationUpdatedDto(conversationId, now), Context.ConnectionAborted);
        await Clients.User(userId.ToString()).SendAsync("conversationUpdated", new ConversationUpdatedDto(conversationId, now), Context.ConnectionAborted);

        await _notificationService.SendToUserAsync(
            receiverId,
            $"New message from {senderName}",
            trimmed.Length > 80 ? $"{trimmed[..80]}..." : trimmed,
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.NewMessage,
                ["referenceId"] = conversationId.ToString()
            },
            Context.ConnectionAborted);
    }

    public async Task MarkConversationAsRead(Guid conversationId)
    {
        var (userId, conversation) = await GetAuthorizedConversationAsync(conversationId, Context.ConnectionAborted);
        _ = conversation;

        var unreadIncoming = await _dbContext.ChatMessages
            .Where(x => x.ConversationId == conversationId && x.SenderId != userId && !x.IsRead)
            .ToListAsync(Context.ConnectionAborted);
        if (unreadIncoming.Count == 0)
        {
            return;
        }

        foreach (var item in unreadIncoming)
        {
            item.IsRead = true;
        }

        await _dbContext.SaveChangesAsync(Context.ConnectionAborted);
        await Clients.Group(GetConversationGroup(conversationId)).SendAsync("messagesRead", new MessagesReadDto(conversationId, userId), Context.ConnectionAborted);
    }

    private async Task<(Guid UserId, Conversation Conversation)> GetAuthorizedConversationAsync(Guid conversationId, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(Context.User ?? throw new UnauthorizedException("Unauthorized."));
        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.Id == conversationId, cancellationToken)
            ?? throw new NotFoundException("Conversation not found.");

        if (conversation.PatientId != userId && conversation.DoctorId != userId)
        {
            throw new ForbiddenException("You do not have access to this conversation.");
        }

        return (userId, conversation);
    }

    private static string GetConversationGroup(Guid conversationId) => $"conversation:{conversationId}";

    public sealed record RealtimeMessageDto(
        Guid Id,
        Guid ConversationId,
        Guid SenderId,
        string SenderName,
        string Content,
        DateTime SentAt,
        bool IsRead);

    public sealed record ConversationUpdatedDto(Guid ConversationId, DateTime LastMessageAt);
    public sealed record MessagesReadDto(Guid ConversationId, Guid ReaderId);
}
