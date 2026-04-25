using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.UpdateSpecialty;

public class UpdateSpecialtyCommandHandler : IRequestHandler<UpdateSpecialtyCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;

    public UpdateSpecialtyCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(UpdateSpecialtyCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadRequestException("Name is required.");
        }

        var specialty = await _dbContext.Specialties.FirstOrDefaultAsync(x => x.Id == request.SpecialtyId, cancellationToken)
            ?? throw new NotFoundException("Specialty not found.");

        var normalizedName = request.Name.Trim();
        var duplicate = await _dbContext.Specialties.AnyAsync(
            x => x.Id != request.SpecialtyId && x.Name.ToLower() == normalizedName.ToLower(),
            cancellationToken);
        if (duplicate)
        {
            throw new BadRequestException("Specialty already exists.");
        }

        specialty.Name = normalizedName;
        specialty.IconUrl = request.IconUrl?.Trim();
        specialty.IsActive = request.IsActive ?? specialty.IsActive;

        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "Specialty updated.");
    }
}
