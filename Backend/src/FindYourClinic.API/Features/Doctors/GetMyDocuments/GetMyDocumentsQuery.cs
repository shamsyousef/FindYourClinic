using FindYourClinic.Domain.Common;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetMyDocuments;

public class GetMyDocumentsQuery : IRequest<ApiResponse<List<MyDoctorDocumentDto>>>
{
    public Guid UserId { get; set; }
}

public class MyDoctorDocumentDto
{
    public string DocumentType { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
}
