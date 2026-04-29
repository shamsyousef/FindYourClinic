using FindYourClinic.API.Features.HealthRecords.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.HealthRecords.GetPatientRecords;

public class GetPatientRecordsQuery : IRequest<ApiResponse<List<HealthRecordDto>>>
{
    public Guid DoctorUserId { get; set; }
    public UserRole Role { get; set; }
    public Guid PatientId { get; set; }
    public HealthRecordType? Type { get; set; }
}
