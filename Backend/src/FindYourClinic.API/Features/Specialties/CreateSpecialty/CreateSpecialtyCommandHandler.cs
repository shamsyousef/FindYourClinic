using FindYourClinic.API.Features.Specialties.Shared;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.CreateSpecialty;

public class CreateSpecialtyCommandHandler : IRequestHandler<CreateSpecialtyCommand, ApiResponse<SpecialtyDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public CreateSpecialtyCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<SpecialtyDto>> Handle(CreateSpecialtyCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadRequestException("Name is required.");
        }

        var normalizedName = request.Name.Trim();
        var exists = await _dbContext.Specialties.AnyAsync(
            x => x.Name.ToLower() == normalizedName.ToLower(),
            cancellationToken);
        if (exists)
        {
            throw new BadRequestException("Specialty already exists.");
        }

        var specialty = new Specialty
        {
            Name = normalizedName,
            IconUrl = request.IconUrl?.Trim(),
            IsActive = true
        };
        _dbContext.Specialties.Add(specialty);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ApiResponse<SpecialtyDto>.Ok(new SpecialtyDto(specialty.Id, specialty.Name, specialty.IconUrl), "Specialty created.");
    }
}
