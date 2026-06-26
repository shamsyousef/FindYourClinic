using Ardalis.Result;
using FindYourClinic.API.Features.Specialties.Shared;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Specialties.CreateSpecialty;

public class CreateSpecialtyCommandHandler : IRequestHandler<CreateSpecialtyCommand, Result<SpecialtyDto>>
{
    private readonly ApplicationDbContext _dbContext;

    public CreateSpecialtyCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result<SpecialtyDto>> Handle(CreateSpecialtyCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadRequestException("NAME_REQUIRED");
        }

        var normalizedName = request.Name.Trim();
        var exists = await _dbContext.Specialties.AnyAsync(
            x => x.Name.ToLower() == normalizedName.ToLower(),
            cancellationToken);
        if (exists)
        {
            throw new BadRequestException("SPECIALTY_ALREADY_EXISTS");
        }

        var specialty = new Specialty
        {
            Name = normalizedName,
            IconUrl = request.IconUrl?.Trim(),
            IsActive = true
        };
        _dbContext.Specialties.Add(specialty);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return Result.Success(new SpecialtyDto(specialty.Id, specialty.Name, specialty.IconUrl), "SPECIALTY_CREATED_SUCCESS");
    }
}
