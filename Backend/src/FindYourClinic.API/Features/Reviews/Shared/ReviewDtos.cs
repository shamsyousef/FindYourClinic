namespace FindYourClinic.API.Features.Reviews.Shared;

public sealed record ReviewDto(
    Guid Id,
    Guid PatientId,
    string PatientName,
    int Rating,
    string? Comment,
    DateTime CreatedAt);

public sealed record ReviewListResponse(
    double AvgRating,
    int TotalReviews,
    List<ReviewDto> Reviews);
