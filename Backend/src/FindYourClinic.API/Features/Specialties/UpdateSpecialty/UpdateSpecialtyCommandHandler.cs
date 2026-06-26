using Ardalis.Result;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.UpdateSpecialty;

public class UpdateSpecialtyCommandHandler : IRequestHandler<UpdateSpecialtyCommand, Result<Guid>>
{
    private readonly ApplicationDbContext _dbContext;

    public UpdateSpecialtyCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result<Guid>> Handle(UpdateSpecialtyCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return Result.Invalid(new ValidationError
            {
                Identifier = nameof(request.Name),
                ErrorMessage = "NAME_REQUIRED"
            });
        }

        var specialty = await _dbContext.Specialties.FirstOrDefaultAsync(x => x.Id == request.SpecialtyId, cancellationToken);
        if (specialty == null)
        {
            return Result.NotFound("SPECIALTY_NOT_FOUND");
        }

        var normalizedName = request.Name.Trim();
        var duplicate = await _dbContext.Specialties.AnyAsync(
            x => x.Id != request.SpecialtyId && x.Name.ToLower() == normalizedName.ToLower(),
            cancellationToken);
        if (duplicate)
        {
            return Result.Conflict("SPECIALTY_ALREADY_EXISTS");
        }

        specialty.Name = normalizedName;
        specialty.IconUrl = request.IconUrl?.Trim();
        specialty.IsActive = request.IsActive ?? specialty.IsActive;

        await _dbContext.SaveChangesAsync(cancellationToken);
        return Result.Success(specialty.Id, "SPECIALTY_UPDATED_SUCCESS");
    }
}
