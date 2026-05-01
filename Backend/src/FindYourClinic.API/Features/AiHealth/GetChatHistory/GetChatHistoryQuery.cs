using MediatR;

namespace FindYourClinic.API.Features.AiHealth.GetChatHistory;

public record GetChatHistoryQuery(string UserId) : IRequest<List<ChatMessageDto>>;
public record ChatMessageDto(string Role, string Content, DateTime CreatedAt);
