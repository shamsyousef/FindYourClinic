using Ardalis.Result;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.DeleteSpecialty;

public class DeleteSpecialtyCommandHandler : IRequestHandler<DeleteSpecialtyCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;

    public DeleteSpecialtyCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result> Handle(DeleteSpecialtyCommand request, CancellationToken cancellationToken)
    {
        var specialty = await _dbContext.Specialties.FirstOrDefaultAsync(x => x.Id == request.SpecialtyId, cancellationToken)
            ?? throw new NotFoundException("SPECIALTY_NOT_FOUND");

        specialty.IsActive = false;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return Result.Success("SPECIALTY_DELETED_SUCCESS");
    }
}
