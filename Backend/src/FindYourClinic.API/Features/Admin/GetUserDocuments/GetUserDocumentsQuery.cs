using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Admin.GetUserDocuments;

public record GetUserDocumentsQuery(Guid UserId) : IRequest<ApiResponse<List<DocumentDto>>>;

public class DocumentDto
{
    public string Url { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
}
