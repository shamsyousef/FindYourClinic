using FindYourClinic.API.Services;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.AiHealth.SendMessage;

public class SendMessageCommandHandler : IRequestHandler<SendMessageCommand, SendMessageResult>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IGeminiService _geminiService;

    public SendMessageCommandHandler(ApplicationDbContext dbContext, IGeminiService geminiService)
    {
        _dbContext = dbContext;
        _geminiService = geminiService;
    }

    public async Task<SendMessageResult> Handle(SendMessageCommand request, CancellationToken cancellationToken)
    {
        var userMessage = new AiChatMessage
        {
            UserId = request.UserId,
            Role = "user",
            Content = request.Content,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiChatMessages.Add(userMessage);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var history = await _dbContext.AiChatMessages
            .AsNoTracking()
            .Where(m => m.UserId == request.UserId)
            .OrderByDescending(m => m.CreatedAt)
            .Take(20)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new { m.Role, m.Content })
            .ToListAsync(cancellationToken);

        var conversationHistory = history
            .Select(h => (h.Role, h.Content))
            .ToList();

        var assistantContent = await _geminiService.GenerateResponseAsync(conversationHistory, language: request.Language);

        var assistantMessage = new AiChatMessage
        {
            UserId = request.UserId,
            Role = "assistant",
            Content = assistantContent,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiChatMessages.Add(assistantMessage);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new SendMessageResult(assistantMessage.Role, assistantMessage.Content, assistantMessage.CreatedAt);
    }
}
