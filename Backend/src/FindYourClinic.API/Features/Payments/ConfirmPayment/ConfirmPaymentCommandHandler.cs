using Ardalis.Result;
using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Payments.ConfirmPayment;

public class ConfirmPaymentCommandHandler : IRequestHandler<ConfirmPaymentCommand, Result<AppointmentDto>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;
    private readonly IConfiguration _configuration;

    public ConfirmPaymentCommandHandler(
        ApplicationDbContext dbContext,
        INotificationService notificationService,
        IConfiguration configuration)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
        _configuration = configuration;
    }

    public async Task<Result<AppointmentDto>> Handle(ConfirmPaymentCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
            throw new ForbiddenException("ONLY_PATIENTS_CAN_CONFIRM");

        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .Include(x => x.Specialty)
            .FirstOrDefaultAsync(x => x.Id == request.DoctorProfileId && x.Status == DoctorStatus.Approved, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        // Idempotency: if the webhook already created the appointment for this
        // Paymob order, return it instead of erroring — the user paid, we owe them
        // a confirmed booking, not a "duplicate" error.
        var existing = await _dbContext.Appointments
            .Include(x => x.DoctorProfile).ThenInclude(d => d.User)
            .Include(x => x.DoctorProfile).ThenInclude(d => d.Specialty)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.PaymobOrderId == request.PaymobOrderId, cancellationToken);

        if (existing is not null)
        {
            var existingDto = new AppointmentDto(
                existing.Id,
                existing.PatientId,
                existing.DoctorProfileId,
                existing.DoctorProfile.UserId,
                existing.ScheduledAt,
                existing.LocationName,
                existing.Status.ToString(),
                existing.CreatedAt,
                $"{existing.DoctorProfile.User.FirstName} {existing.DoctorProfile.User.LastName}".Trim(),
                existing.DoctorProfile.User.ProfileImageUrl,
                existing.DoctorProfile.Specialty?.Name,
                existing.PaymentStatus.ToString(),
                existing.PaymentMethod?.ToString(),
                existing.AmountPaid);
            return Result.Success(existingDto, "PAYMENT_ALREADY_CONFIRMED");
        }

        // Verify slot is still available
        var overlapping = await _dbContext.Appointments.AnyAsync(
            x => x.DoctorProfileId == request.DoctorProfileId &&
                 x.ScheduledAt == request.ScheduledAt &&
                 x.Status != AppointmentStatus.Cancelled,
            cancellationToken);
        if (overlapping)
            throw new BadRequestException("SLOT_NO_LONGER_AVAILABLE");

        // Calculate fees
        var consultationFee = doctorProfile.ConsultationFee;
        var commissionPercent = _configuration.GetValue<decimal>("Paymob:CommissionPercent", 10);
        var platformFee = Math.Round(consultationFee * commissionPercent / 100, 2);
        var doctorEarnings = consultationFee - platformFee;

        // Create appointment (auto-confirmed since payment succeeded)
        var appointment = new Appointment
        {
            PatientId = request.UserId,
            DoctorProfileId = request.DoctorProfileId,
            ScheduledAt = request.ScheduledAt,
            LocationName = string.IsNullOrWhiteSpace(request.LocationName) ? doctorProfile.ClinicName : request.LocationName.Trim(),
            Status = AppointmentStatus.Confirmed,
            PaymentStatus = PaymentStatus.Paid,
            PaymentMethod = request.PaymentMethod,
            PaymobOrderId = request.PaymobOrderId,
            PaymobTransactionId = request.PaymobTransactionId,
            AmountPaid = consultationFee
        };

        _dbContext.Appointments.Add(appointment);

        // Create transaction record
        var transaction = new Transaction
        {
            AppointmentId = appointment.Id,
            PatientId = request.UserId,
            DoctorProfileId = request.DoctorProfileId,
            Amount = consultationFee,
            PlatformFee = platformFee,
            DoctorEarnings = doctorEarnings,
            PaymobOrderId = request.PaymobOrderId,
            PaymobTransactionId = request.PaymobTransactionId,
            PaymentMethod = request.PaymentMethod,
            Status = PaymentStatus.Paid,
            CompletedAt = DateTime.UtcNow
        };

        _dbContext.Transactions.Add(transaction);

        // Update or create doctor wallet
        var wallet = await _dbContext.DoctorWallets
            .FirstOrDefaultAsync(x => x.DoctorProfileId == request.DoctorProfileId, cancellationToken);

        if (wallet is null)
        {
            wallet = new DoctorWallet
            {
                DoctorProfileId = request.DoctorProfileId,
                TotalEarnings = doctorEarnings,
                PendingBalance = doctorEarnings
            };
            _dbContext.DoctorWallets.Add(wallet);
        }
        else
        {
            wallet.TotalEarnings += doctorEarnings;
            wallet.PendingBalance += doctorEarnings;
        }

        // Mark the pending intent (if any) as consumed.
        var intent = await _dbContext.PendingBookingIntents
            .FirstOrDefaultAsync(x => x.PaymobOrderId == request.PaymobOrderId, cancellationToken);
        if (intent is not null && !intent.IsConsumed)
        {
            intent.IsConsumed = true;
            intent.ConsumedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        // Notify doctor
        await _notificationService.SendToUserAsync(
            doctorProfile.UserId,
            "New paid appointment",
            $"A patient booked and paid for an appointment on {appointment.ScheduledAt:MMM dd 'at' hh:mm tt}.",
            new Dictionary<string, string>
            {
                ["type"] = NotificationTypes.AppointmentBooked,
                ["referenceId"] = appointment.Id.ToString()
            },
            cancellationToken);

        var dto = new AppointmentDto(
            appointment.Id,
            appointment.PatientId,
            appointment.DoctorProfileId,
            doctorProfile.UserId,
            appointment.ScheduledAt,
            appointment.LocationName,
            appointment.Status.ToString(),
            appointment.CreatedAt,
            $"{doctorProfile.User.FirstName} {doctorProfile.User.LastName}".Trim(),
            doctorProfile.User.ProfileImageUrl,
            doctorProfile.Specialty?.Name,
            appointment.PaymentStatus.ToString(),
            appointment.PaymentMethod?.ToString(),
            appointment.AmountPaid);

        return Result.Success(dto, "PAYMENT_CONFIRMED_SUCCESS");
    }
}
