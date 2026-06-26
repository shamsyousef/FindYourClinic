using Ardalis.Result;
using MediatR;

namespace FindYourClinic.API.Features.Specialties.DeleteSpecialty;

public class DeleteSpecialtyCommand : IRequest<Result>
{
    public Guid SpecialtyId { get; set; }
}
