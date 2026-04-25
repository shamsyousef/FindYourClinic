using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.DeleteSpecialty;

public class DeleteSpecialtyCommandHandler : IRequestHandler<DeleteSpecialtyCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;

    public DeleteSpecialtyCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(DeleteSpecialtyCommand request, CancellationToken cancellationToken)
    {
        var specialty = await _dbContext.Specialties.FirstOrDefaultAsync(x => x.Id == request.SpecialtyId, cancellationToken)
            ?? throw new NotFoundException("Specialty not found.");

        specialty.IsActive = false;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "Specialty deleted.");
    }
}
