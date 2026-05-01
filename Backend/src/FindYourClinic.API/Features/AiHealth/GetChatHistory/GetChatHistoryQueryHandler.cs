using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.AiHealth.GetChatHistory;

public class GetChatHistoryQueryHandler : IRequestHandler<GetChatHistoryQuery, List<ChatMessageDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public GetChatHistoryQueryHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<ChatMessageDto>> Handle(GetChatHistoryQuery request, CancellationToken cancellationToken)
    {
        return await _dbContext.AiChatMessages
            .AsNoTracking()
            .Where(m => m.UserId == request.UserId)
            .OrderBy(m => m.CreatedAt)
            .Take(50)
            .Select(m => new ChatMessageDto(m.Role, m.Content, m.CreatedAt))
            .ToListAsync(cancellationToken);
    }
}
