using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Reviews.AddReview;

public class AddReviewCommandHandler : IRequestHandler<AddReviewCommand, ApiResponse<object>>
{
    private readonly ApplicationDbContext _dbContext;

    public AddReviewCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ApiResponse<object>> Handle(AddReviewCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
        {
            throw new ForbiddenException("Only patients can submit reviews.");
        }

        if (request.Rating is < 1 or > 5)
        {
            throw new BadRequestException("Rating must be between 1 and 5.");
        }

        var doctorProfile = await _dbContext.DoctorProfiles
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId && x.Status == DoctorStatus.Approved, cancellationToken)
            ?? throw new NotFoundException("Doctor not found.");

        var hadCompletedAppointment = await _dbContext.Appointments.AnyAsync(
            x => x.PatientId == request.UserId &&
                 x.DoctorProfileId == doctorProfile.Id &&
                 x.Status == AppointmentStatus.Completed,
            cancellationToken);
        if (!hadCompletedAppointment)
        {
            throw new ForbiddenException("You can only review doctors after completed appointments.");
        }

        var existing = await _dbContext.DoctorReviews.FirstOrDefaultAsync(
            x => x.DoctorProfileId == doctorProfile.Id && x.PatientId == request.UserId,
            cancellationToken);
        if (existing is null)
        {
            var review = new DoctorReview
            {
                DoctorProfileId = doctorProfile.Id,
                PatientId = request.UserId,
                Rating = request.Rating,
                Comment = request.Comment?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.DoctorReviews.Add(review);
        }
        else
        {
            existing.Rating = request.Rating;
            existing.Comment = request.Comment?.Trim();
            existing.CreatedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        return ApiResponse<object>.Ok(null, "Review submitted.");
    }
}
