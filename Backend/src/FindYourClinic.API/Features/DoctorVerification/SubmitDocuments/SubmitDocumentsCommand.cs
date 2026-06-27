using FindYourClinic.Domain.Common;
using MediatR;
using Microsoft.AspNetCore.Http;

namespace FindYourClinic.API.Features.DoctorVerification.SubmitDocuments;

public class SubmitDocumentsCommand : IRequest<ApiResponse<List<UploadedDoctorDocumentDto>>>
{
    public Guid DoctorUserId { get; set; }
    public List<IFormFile> Files { get; set; } = [];
    public List<string> DocumentTypes { get; set; } = [];
}

public class UploadedDoctorDocumentDto
{
    public string DocumentType { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
}
