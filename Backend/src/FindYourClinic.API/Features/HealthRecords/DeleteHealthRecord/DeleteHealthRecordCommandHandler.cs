using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.HealthRecords.DeleteHealthRecord;

public class DeleteHealthRecordCommandHandler : IRequestHandler<DeleteHealthRecordCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;

    public DeleteHealthRecordCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(DeleteHealthRecordCommand request, CancellationToken cancellationToken)
    {
        EnsurePatient(request.Role);

        var record = await _dbContext.HealthRecords.FirstOrDefaultAsync(x => x.Id == request.RecordId && x.PatientId == request.UserId, cancellationToken)
            ?? throw new NotFoundException("Health record not found.");

        _dbContext.HealthRecords.Remove(record);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "Health record deleted.");
    }

    private static void EnsurePatient(UserRole role)
    {
        if (role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can access health records.");
        }
    }
}
