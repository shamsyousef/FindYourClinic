using MediatR;

namespace FindYourClinic.API.Features.AiHealth.SendMessage;

public record SendMessageCommand(string UserId, string Content) : IRequest<SendMessageResult>;
public record SendMessageResult(string Role, string Content, DateTime CreatedAt);
