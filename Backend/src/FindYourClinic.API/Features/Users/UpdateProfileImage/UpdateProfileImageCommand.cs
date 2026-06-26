using Ardalis.Result;
using MediatR;
using Microsoft.AspNetCore.Http;

namespace FindYourClinic.API.Features.Users.UpdateProfileImage;

public class UpdateProfileImageCommand : IRequest<Result<string>>
{
    public Guid UserId { get; set; }
    public IFormFile File { get; set; } = null!;
}
