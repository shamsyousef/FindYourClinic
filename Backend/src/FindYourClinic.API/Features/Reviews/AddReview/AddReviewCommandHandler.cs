using Ardalis.Result;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Reviews.AddReview;

public class AddReviewCommandHandler : IRequestHandler<AddReviewCommand, Result>
{
    private readonly ApplicationDbContext _dbContext;

    public AddReviewCommandHandler(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Result> Handle(AddReviewCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
        {
            throw new ForbiddenException("ONLY_PATIENTS_CAN_SUBMIT_REVIEWS");
        }

        if (request.Rating is < 1 or > 5)
        {
            throw new BadRequestException("RATING_MUST_BE_BETWEEN_1_AND_5");
        }

        var doctorProfile = await _dbContext.DoctorProfiles
            .FirstOrDefaultAsync(x => x.UserId == request.DoctorId && x.Status == DoctorStatus.Approved, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_NOT_FOUND");

        var hadCompletedAppointment = await _dbContext.Appointments.AnyAsync(
            x => x.PatientId == request.UserId &&
                 x.DoctorProfileId == doctorProfile.Id &&
                 x.Status == AppointmentStatus.Completed,
            cancellationToken);
        if (!hadCompletedAppointment)
        {
            throw new ForbiddenException("ONLY_REVIEW_DOCTORS_AFTER_COMPLETED_APPOINTMENTS");
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
        return Result.Success("REVIEW_SUBMITTED_SUCCESS");
    }
}
