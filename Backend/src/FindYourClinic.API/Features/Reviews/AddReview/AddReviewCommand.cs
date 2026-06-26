using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Reviews.AddReview;

public class AddReviewCommand : IRequest<Result>
{
    public Guid DoctorId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
