using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Reviews.AddReview;

public class AddReviewCommand : IRequest<ApiResponse<object>>
{
    public Guid DoctorId { get; set; }
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
