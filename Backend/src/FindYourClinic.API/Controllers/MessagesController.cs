using FindYourClinic.API.Common;
using FindYourClinic.API.Hubs;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Interfaces;
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
    private const long MaxImageBytes = 5 * 1024 * 1024;     // 5 MB
    private const long MaxVideoBytes = 50 * 1024 * 1024;    // 50 MB
    private const long MaxVoiceBytes = 10 * 1024 * 1024;    // 10 MB

    private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"
    };

    private static readonly HashSet<string> AllowedVideoContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "video/mp4", "video/quicktime", "video/3gpp", "video/x-m4v", "video/webm"
    };

    private static readonly HashSet<string> AllowedVoiceContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "audio/aac", "audio/mp4", "audio/mpeg", "audio/m4a", "audio/x-m4a",
        "audio/ogg", "audio/webm", "audio/wav", "audio/x-wav"
    };

    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;
    private readonly IHubContext<ChatHub> _hubContext;
    private readonly ICloudinaryService _cloudinaryService;

    public MessagesController(
        ApplicationDbContext dbContext,
        INotificationService notificationService,
        IHubContext<ChatHub> hubContext,
        ICloudinaryService cloudinaryService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
        _hubContext = hubContext;
        _cloudinaryService = cloudinaryService;
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
                x.Messages
                    .OrderByDescending(m => m.SentAt)
                    .Select(m => m.Type == ChatMessageType.Text ? m.Content : MediaPreviewLabel(m.Type))
                    .FirstOrDefault(),
                role == UserRole.Patient ? $"{x.Doctor.FirstName} {x.Doctor.LastName}".Trim() : $"{x.Patient.FirstName} {x.Patient.LastName}".Trim(),
                role == UserRole.Patient ? x.Doctor.ProfileImageUrl : x.Patient.ProfileImageUrl,
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
            .Include(x => x.ReplyToMessage)
            .Include(x => x.Reactions)
            .Where(x => x.ConversationId == id)
            .OrderBy(x => x.SentAt)
            .Select(x => new MessageDto(
                x.Id,
                x.ConversationId,
                x.SenderId,
                $"{x.Sender.FirstName} {x.Sender.LastName}".Trim(),
                x.Content,
                x.SentAt,
                x.IsRead,
                (int)x.Type,
                x.MediaUrl,
                x.MediaThumbnailUrl,
                x.MediaDurationSeconds,
                x.ReplyToMessageId,
                x.ReplyToMessage == null
                    ? null
                    : new ReplyPreviewDto(
                        x.ReplyToMessage.Id,
                        x.ReplyToMessage.SenderId,
                        x.ReplyToMessage.Content,
                        (int)x.ReplyToMessage.Type),
                x.Reactions.Select(r => new ReactionDto(r.UserId, r.Emoji)).ToList()))
            .ToListAsync(cancellationToken);

        return Ok(ApiResponse<List<MessageDto>>.Ok(messages));
    }

    [HttpPost("conversations/{counterpartyId:guid}")]
    public async Task<IActionResult> StartOrGetConversation([FromRoute] Guid counterpartyId, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var role = UserContext.GetRequiredRole(User);

        if (role != UserRole.Patient && role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only patients and doctors can start conversations.");
        }

        Guid patientId = role == UserRole.Patient ? userId : counterpartyId;
        Guid doctorId = role == UserRole.Doctor ? userId : counterpartyId;

        var counterpartyExists = await _dbContext.Users.AnyAsync(
            x => x.Id == counterpartyId && x.IsActive,
            cancellationToken);

        if (!counterpartyExists)
        {
            throw new NotFoundException("User not found.");
        }

        await EnsureValidAppointmentAsync(patientId, doctorId, cancellationToken);

        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.PatientId == patientId && x.DoctorId == doctorId, cancellationToken);
        if (conversation is null)
        {
            conversation = new Conversation
            {
                PatientId = patientId,
                DoctorId = doctorId,
                LastMessageAt = DateTime.UtcNow
            };
            _dbContext.Conversations.Add(conversation);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return Ok(ApiResponse<ConversationDto>.Ok(new ConversationDto(conversation.Id, conversation.PatientId, conversation.DoctorId, conversation.LastMessageAt, null, null, null, 0)));
    }

    [HttpPost("conversations/{id:guid}/send")]
    public async Task<IActionResult> SendMessage([FromRoute] Guid id, [FromBody] SendMessageRequest request, CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await GetParticipantConversationAsync(id, userId, cancellationToken);
        await EnsureValidAppointmentAsync(conversation.PatientId, conversation.DoctorId, cancellationToken);

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new BadRequestException("Message content is required.");
        }

        await EnsureReplyTargetAsync(request.ReplyToMessageId, id, cancellationToken);

        var trimmed = request.Content.Trim();
        var message = await PersistAndBroadcastAsync(
            conversation,
            userId,
            ChatMessageType.Text,
            content: trimmed,
            mediaUrl: null,
            mediaThumbnailUrl: null,
            mediaDurationSeconds: null,
            replyToMessageId: request.ReplyToMessageId,
            previewBody: trimmed,
            cancellationToken);

        return Ok(ApiResponse<MessageDto>.Ok(message, "Message sent."));
    }

    [HttpPost("conversations/{id:guid}/send-image")]
    [RequestSizeLimit(MaxImageBytes + 1024)]
    public async Task<IActionResult> SendImage(
        [FromRoute] Guid id,
        [FromForm] IFormFile image,
        [FromForm] Guid? replyToMessageId,
        [FromForm] string? caption,
        CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await GetParticipantConversationAsync(id, userId, cancellationToken);
        await EnsureValidAppointmentAsync(conversation.PatientId, conversation.DoctorId, cancellationToken);
        ValidateFile(image, MaxImageBytes, AllowedImageContentTypes, "image");
        await EnsureReplyTargetAsync(replyToMessageId, id, cancellationToken);

        var upload = await _cloudinaryService.UploadImageAsync(image, $"clinic/chat/{id}/images");
        var caption_ = caption?.Trim() ?? string.Empty;
        var message = await PersistAndBroadcastAsync(
            conversation,
            userId,
            ChatMessageType.Image,
            content: caption_,
            mediaUrl: upload.Url,
            mediaThumbnailUrl: upload.Url,
            mediaDurationSeconds: null,
            replyToMessageId: replyToMessageId,
            previewBody: "📷 Photo",
            cancellationToken);

        return Ok(ApiResponse<MessageDto>.Ok(message, "Image sent."));
    }

    [HttpPost("conversations/{id:guid}/send-video")]
    [RequestSizeLimit(MaxVideoBytes + 1024)]
    public async Task<IActionResult> SendVideo(
        [FromRoute] Guid id,
        [FromForm] IFormFile video,
        [FromForm] Guid? replyToMessageId,
        [FromForm] string? caption,
        CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await GetParticipantConversationAsync(id, userId, cancellationToken);
        await EnsureValidAppointmentAsync(conversation.PatientId, conversation.DoctorId, cancellationToken);
        ValidateFile(video, MaxVideoBytes, AllowedVideoContentTypes, "video");
        await EnsureReplyTargetAsync(replyToMessageId, id, cancellationToken);

        var upload = await _cloudinaryService.UploadVideoAsync(video, $"clinic/chat/{id}/videos");
        var caption_ = caption?.Trim() ?? string.Empty;
        var message = await PersistAndBroadcastAsync(
            conversation,
            userId,
            ChatMessageType.Video,
            content: caption_,
            mediaUrl: upload.Url,
            mediaThumbnailUrl: upload.ThumbnailUrl,
            mediaDurationSeconds: upload.DurationSeconds,
            replyToMessageId: replyToMessageId,
            previewBody: "🎥 Video",
            cancellationToken);

        return Ok(ApiResponse<MessageDto>.Ok(message, "Video sent."));
    }

    [HttpPost("conversations/{id:guid}/send-voice")]
    [RequestSizeLimit(MaxVoiceBytes + 1024)]
    public async Task<IActionResult> SendVoice(
        [FromRoute] Guid id,
        [FromForm] IFormFile audio,
        [FromForm] int? durationSeconds,
        [FromForm] Guid? replyToMessageId,
        CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);
        var conversation = await GetParticipantConversationAsync(id, userId, cancellationToken);
        await EnsureValidAppointmentAsync(conversation.PatientId, conversation.DoctorId, cancellationToken);
        ValidateFile(audio, MaxVoiceBytes, AllowedVoiceContentTypes, "audio");
        await EnsureReplyTargetAsync(replyToMessageId, id, cancellationToken);

        var upload = await _cloudinaryService.UploadFileAsync(audio, $"clinic/chat/{id}/voice");
        var message = await PersistAndBroadcastAsync(
            conversation,
            userId,
            ChatMessageType.Voice,
            content: string.Empty,
            mediaUrl: upload.Url,
            mediaThumbnailUrl: null,
            mediaDurationSeconds: durationSeconds,
            replyToMessageId: replyToMessageId,
            previewBody: "🎙 Voice message",
            cancellationToken);

        return Ok(ApiResponse<MessageDto>.Ok(message, "Voice message sent."));
    }

    [HttpPost("messages/{messageId:guid}/react")]
    public async Task<IActionResult> ReactToMessage(
        [FromRoute] Guid messageId,
        [FromBody] ReactRequest request,
        CancellationToken cancellationToken)
    {
        var userId = UserContext.GetRequiredUserId(User);

        if (string.IsNullOrWhiteSpace(request.Emoji) || request.Emoji.Length > 16)
        {
            throw new BadRequestException("Invalid emoji.");
        }

        var message = await _dbContext.ChatMessages
            .Include(x => x.Conversation)
            .FirstOrDefaultAsync(x => x.Id == messageId, cancellationToken)
            ?? throw new NotFoundException("Message not found.");

        EnsureParticipant(message.Conversation, userId);

        var emoji = request.Emoji.Trim();
        var existing = await _dbContext.MessageReactions
            .Where(x => x.MessageId == messageId && x.UserId == userId)
            .ToListAsync(cancellationToken);

        // Users have at most one reaction per message; replace if different, toggle off if same.
        var hadSame = existing.Any(x => x.Emoji == emoji);
        if (existing.Count > 0)
        {
            _dbContext.MessageReactions.RemoveRange(existing);
        }
        if (!hadSame)
        {
            _dbContext.MessageReactions.Add(new MessageReaction
            {
                MessageId = messageId,
                UserId = userId,
                Emoji = emoji
            });
        }
        await _dbContext.SaveChangesAsync(cancellationToken);

        var reactions = await _dbContext.MessageReactions
            .AsNoTracking()
            .Where(x => x.MessageId == messageId)
            .Select(x => new ReactionDto(x.UserId, x.Emoji))
            .ToListAsync(cancellationToken);

        await _hubContext.Clients
            .Group($"conversation:{message.ConversationId}")
            .SendAsync(
                "reactionUpdated",
                new ChatHub.ReactionUpdatedDto(message.ConversationId, messageId, reactions.Select(r => new ChatHub.ReactionDto(r.UserId, r.Emoji)).ToList()),
                cancellationToken);

        return Ok(ApiResponse<List<ReactionDto>>.Ok(reactions, "Reaction updated."));
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

    private async Task<MessageDto> PersistAndBroadcastAsync(
        Conversation conversation,
        Guid senderId,
        ChatMessageType type,
        string content,
        string? mediaUrl,
        string? mediaThumbnailUrl,
        int? mediaDurationSeconds,
        Guid? replyToMessageId,
        string previewBody,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var message = new ChatMessage
        {
            ConversationId = conversation.Id,
            SenderId = senderId,
            Content = content,
            SentAt = now,
            IsRead = false,
            Type = type,
            MediaUrl = mediaUrl,
            MediaThumbnailUrl = mediaThumbnailUrl,
            MediaDurationSeconds = mediaDurationSeconds,
            ReplyToMessageId = replyToMessageId
        };
        conversation.LastMessageAt = now;
        _dbContext.ChatMessages.Add(message);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var senderName = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == senderId)
            .Select(x => $"{x.FirstName} {x.LastName}".Trim())
            .FirstOrDefaultAsync(cancellationToken) ?? "Someone";

        ReplyPreviewDto? replyPreview = null;
        if (replyToMessageId is { } replyId)
        {
            replyPreview = await _dbContext.ChatMessages
                .AsNoTracking()
                .Where(x => x.Id == replyId)
                .Select(x => new ReplyPreviewDto(x.Id, x.SenderId, x.Content, (int)x.Type))
                .FirstOrDefaultAsync(cancellationToken);
        }

        var receiverId = conversation.PatientId == senderId ? conversation.DoctorId : conversation.PatientId;

        await _notificationService.SendToUserAsync(
            receiverId,
            $"New message from {senderName}",
            previewBody.Length > 80 ? $"{previewBody[..80]}..." : previewBody,
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
            message.IsRead,
            (int)message.Type,
            message.MediaUrl,
            message.MediaThumbnailUrl,
            message.MediaDurationSeconds,
            message.ReplyToMessageId,
            replyPreview == null ? null : new ChatHub.ReplyPreviewDto(replyPreview.Id, replyPreview.SenderId, replyPreview.Content, replyPreview.Type),
            new List<ChatHub.ReactionDto>());

        await _hubContext.Clients.Group($"conversation:{conversation.Id}").SendAsync("messageReceived", realtimeMessage, cancellationToken);
        await _hubContext.Clients.User(receiverId.ToString()).SendAsync("conversationUpdated", new ChatHub.ConversationUpdatedDto(conversation.Id, message.SentAt), cancellationToken);
        await _hubContext.Clients.User(senderId.ToString()).SendAsync("conversationUpdated", new ChatHub.ConversationUpdatedDto(conversation.Id, message.SentAt), cancellationToken);

        return new MessageDto(
            message.Id,
            message.ConversationId,
            message.SenderId,
            senderName,
            message.Content,
            message.SentAt,
            message.IsRead,
            (int)message.Type,
            message.MediaUrl,
            message.MediaThumbnailUrl,
            message.MediaDurationSeconds,
            message.ReplyToMessageId,
            replyPreview,
            new List<ReactionDto>());
    }

    private async Task<Conversation> GetParticipantConversationAsync(Guid conversationId, Guid userId, CancellationToken cancellationToken)
    {
        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(x => x.Id == conversationId, cancellationToken)
            ?? throw new NotFoundException("Conversation not found.");
        EnsureParticipant(conversation, userId);
        return conversation;
    }

    private static void EnsureParticipant(Conversation conversation, Guid userId)
    {
        if (conversation.PatientId != userId && conversation.DoctorId != userId)
        {
            throw new ForbiddenException("You do not have access to this conversation.");
        }
    }

    private async Task EnsureValidAppointmentAsync(Guid patientId, Guid doctorId, CancellationToken cancellationToken)
    {
        var hasValidAppointment = await _dbContext.Appointments.AnyAsync(
            x => x.PatientId == patientId && x.DoctorProfile.UserId == doctorId &&
                 (x.Status == AppointmentStatus.Confirmed || x.Status == AppointmentStatus.Completed),
            cancellationToken);

        if (!hasValidAppointment)
        {
            throw new ForbiddenException("You can only chat with doctors you have a confirmed or completed appointment with.");
        }
    }

    private async Task EnsureReplyTargetAsync(Guid? replyToMessageId, Guid conversationId, CancellationToken cancellationToken)
    {
        if (replyToMessageId is null)
        {
            return;
        }

        var belongs = await _dbContext.ChatMessages
            .AnyAsync(x => x.Id == replyToMessageId && x.ConversationId == conversationId, cancellationToken);
        if (!belongs)
        {
            throw new BadRequestException("Reply target does not belong to this conversation.");
        }
    }

    private static void ValidateFile(IFormFile file, long maxBytes, HashSet<string> allowedContentTypes, string kind)
    {
        if (file is null || file.Length == 0)
        {
            throw new BadRequestException($"No {kind} file provided.");
        }
        if (file.Length > maxBytes)
        {
            throw new BadRequestException($"{kind} file exceeds the maximum allowed size.");
        }
        if (!allowedContentTypes.Contains(file.ContentType))
        {
            throw new BadRequestException($"Unsupported {kind} format.");
        }
    }

    private static string MediaPreviewLabel(ChatMessageType type) => type switch
    {
        ChatMessageType.Image => "📷 Photo",
        ChatMessageType.Video => "🎥 Video",
        ChatMessageType.Voice => "🎙 Voice message",
        _ => string.Empty
    };

    public sealed class SendMessageRequest
    {
        public string Content { get; set; } = string.Empty;
        public Guid? ReplyToMessageId { get; set; }
    }

    public sealed class ReactRequest
    {
        public string Emoji { get; set; } = string.Empty;
    }

    public sealed record ConversationDto(
        Guid Id,
        Guid PatientId,
        Guid DoctorId,
        DateTime LastMessageAt,
        string? LastMessage,
        string? CounterpartyName,
        string? CounterpartyImageUrl,
        int UnreadCount);

    public sealed record MessageDto(
        Guid Id,
        Guid ConversationId,
        Guid SenderId,
        string SenderName,
        string Content,
        DateTime SentAt,
        bool IsRead,
        int Type,
        string? MediaUrl,
        string? MediaThumbnailUrl,
        int? MediaDurationSeconds,
        Guid? ReplyToMessageId,
        ReplyPreviewDto? ReplyPreview,
        List<ReactionDto> Reactions);

    public sealed record ReplyPreviewDto(Guid Id, Guid SenderId, string Content, int Type);
    public sealed record ReactionDto(Guid UserId, string Emoji);
}
