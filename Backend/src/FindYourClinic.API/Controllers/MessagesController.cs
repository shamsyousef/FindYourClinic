using FindYourClinic.API.Common;
using FindYourClinic.API.Hubs;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/messages")]
[Authorize]
public class MessagesController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;
    private readonly IHubContext<ChatHub> _hubContext;

    public MessagesController(
        ApplicationDbContext dbContext,
        INotificationService notificationService,
        IHubContext<ChatHub> hubContext)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
        _hubContext = hubContext;
    }

    [HttpGet("conversations")]
    public async Task<IActionResult> GetMyConversations(CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var role = UserContext.GetRequiredRole(User);

        var query = _dbContext.Conversations
            .AsNoTracking()
            .Include(x => x.Patient)
            .Include(x => x.Doctor)
            .Include(x => x.Messages)
            .AsQueryable();

        query = role switch
        {
            UserRole.Patient => query.Where(x => x.PatientId == userId),
            UserRole.Doctor => query.Where(x => x.DoctorId == userId),
            _ => throw new ForbiddenException("Unsupported role for messaging.")
        };

        var items = await query
            .OrderByDescending(x => x.LastMessageAt)
            .Select(x => new ConversationDto(
                x.Id,
                x.PatientId,
                x.DoctorId,
                x.LastMessageAt,
                x.Messages.OrderByDescending(m => m.SentAt).Select(m => m.Content).FirstOrDefault(),
                role == UserRole.Patient ? $"{x.Doctor.FirstName} {x.Doctor.LastName}".Trim() : $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                x.Messages.Count(m => m.SenderId != userId && !m.IsRead)))
            .ToListAsync(cancellationToken);

        return Ok(ApiResponse<List<ConversationDto>>.Ok(items));
    }

    [HttpGet("conversations/{id:guid}")]
    public async Task<IActionResult> GetConversationMessages([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            ?? throw new NotFoundException("Conversation not found.");

        EnsureParticipant(conversation, userId);

        var unreadIncoming = await _dbContext.ChatMessages
            .Where(x => x.ConversationId == id && x.SenderId != userId && !x.IsRead)
            .ToListAsync(cancellationToken);
        foreach (var unreadMessage in unreadIncoming)
        {
            unreadMessage.IsRead = true;
        }
        if (unreadIncoming.Count > 0)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        var messages = await _dbContext.ChatMessages
            .AsNoTracking()
            .Include(x => x.Sender)
            .Where(x => x.ConversationId == id)
            .OrderBy(x => x.SentAt)
            .Select(x => new MessageDto(
                x.Id,
                x.ConversationId,
                x.SenderId,
                $"{x.Sender.FirstName} {x.Sender.LastName}".Trim(),
                x.Content,
                x.SentAt,
                x.IsRead))
            .ToListAsync(cancellationToken);

        return Ok(ApiResponse<List<MessageDto>>.Ok(messages));
    }

    [HttpPost("conversations/{doctorId:guid}")]
    public async Task<IActionResult> StartOrGetConversation([FromRoute] Guid doctorId, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        if (UserContext.GetRequiredRole(User) != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can start conversations.");
        }

        var doctorExists = await _dbContext.Users.AnyAsync(
            x => x.Id == doctorId && x.Role == UserRole.Doctor && x.IsActive,
            cancellationToken);
        if (!doctorExists)
        {
            throw new NotFoundException("Doctor not found.");
        }

        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.PatientId == userId && x.DoctorId == doctorId, cancellationToken);
        if (conversation is null)
        {
            conversation = new Conversation
            {
                PatientId = userId,
                DoctorId = doctorId,
                LastMessageAt = DateTime.UtcNow
            };
            _dbContext.Conversations.Add(conversation);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return Ok(ApiResponse<ConversationDto>.Ok(new ConversationDto(conversation.Id, conversation.PatientId, conversation.DoctorId, conversation.LastMessageAt, null, null, 0)));
    }

    [HttpPost("conversations/{id:guid}/send")]
    public async Task<IActionResult> SendMessage([FromRoute] Guid id, [FromBody] SendMessageRequest request, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            ?? throw new NotFoundException("Conversation not found.");

        EnsureParticipant(conversation, userId);

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new BadRequestException("Message content is required.");
        }

        var message = new ChatMessage
        {
            ConversationId = id,
            SenderId = userId,
            Content = request.Content.Trim(),
            SentAt = DateTime.UtcNow,
            IsRead = false
        };
        conversation.LastMessageAt = message.SentAt;

        _dbContext.ChatMessages.Add(message);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var receiverId = conversation.PatientId == userId ? conversation.DoctorId : conversation.PatientId;
        var senderName = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => $"{x.FirstName} {x.LastName}".Trim())
            .FirstOrDefaultAsync(cancellationToken) ?? "Someone";

        await _notificationService.SendToUserAsync(
            receiverId,
            $"New message from {senderName}",
            request.Content.Trim().Length > 80 ? $"{request.Content.Trim()[..80]}..." : request.Content.Trim(),
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.NewMessage,
                ["referenceId"] = conversation.Id.ToString()
            },
            cancellationToken);

        var realtimeMessage = new ChatHub.RealtimeMessageDto(
            message.Id,
            message.ConversationId,
            message.SenderId,
            senderName,
            message.Content,
            message.SentAt,
            message.IsRead);

        await _hubContext.Clients.Group($"conversation:{id}").SendAsync("messageReceived", realtimeMessage, cancellationToken);
        await _hubContext.Clients.User(receiverId.ToString()).SendAsync("conversationUpdated", new ChatHub.ConversationUpdatedDto(id, message.SentAt), cancellationToken);
        await _hubContext.Clients.User(userId.ToString()).SendAsync("conversationUpdated", new ChatHub.ConversationUpdatedDto(id, message.SentAt), cancellationToken);

        return Ok(ApiResponse<MessageDto>.Ok(new MessageDto(message.Id, message.ConversationId, message.SenderId, string.Empty, message.Content, message.SentAt, message.IsRead), "Message sent."));
    }

    [HttpPut("conversations/{id:guid}/read")]
    public async Task<IActionResult> MarkConversationAsRead([FromRoute] Guid id, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            ?? throw new NotFoundException("Conversation not found.");

        EnsureParticipant(conversation, userId);

        var unreadIncoming = await _dbContext.ChatMessages
            .Where(x => x.ConversationId == id && x.SenderId != userId && !x.IsRead)
            .ToListAsync(cancellationToken);

        foreach (var message in unreadIncoming)
        {
            message.IsRead = true;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        await _hubContext.Clients.Group($"conversation:{id}")
            .SendAsync("messagesRead", new ChatHub.MessagesReadDto(id, userId), cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Conversation marked as read."));
    }

    private static void EnsureParticipant(Conversation conversation, Guid userId)
    {
        if (conversation.PatientId != userId && conversation.DoctorId != userId)
        {
            throw new ForbiddenException("You do not have access to this conversation.");
        }
    }

    public sealed class SendMessageRequest
    {
        public string Content { get; set; } = string.Empty;
    }

    public sealed record ConversationDto(
        Guid ConversationId,
        Guid PatientId,
        Guid DoctorId,
        DateTime LastMessageAt,
        string? LastMessage,
        string? CounterpartyName,
        int UnreadCount);

    public sealed record MessageDto(
        Guid Id,
        Guid ConversationId,
        Guid SenderId,
        string SenderName,
        string Content,
        DateTime SentAt,
        bool IsRead);
}
