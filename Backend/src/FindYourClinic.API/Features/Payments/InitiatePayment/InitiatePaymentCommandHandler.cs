using Ardalis.Result;
using FindYourClinic.API.Services;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Payments.InitiatePayment;

public class InitiatePaymentCommandHandler : IRequestHandler<InitiatePaymentCommand, Result<InitiatePaymentResult>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IPaymobService _paymobService;
    private readonly INotificationService _notificationService;
    private readonly IConfiguration _configuration;

    public InitiatePaymentCommandHandler(
        ApplicationDbContext dbContext,
        IPaymobService paymobService,
        INotificationService notificationService,
        IConfiguration configuration)
    {
        _dbContext = dbContext;
        _paymobService = paymobService;
        _notificationService = notificationService;
        _configuration = configuration;
    }

    public async Task<Result<InitiatePaymentResult>> Handle(InitiatePaymentCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
            throw new ForbiddenException("ONLY_PATIENTS_CAN_BOOK");

        // Validate doctor
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == request.DoctorProfileId && x.Status == DoctorStatus.Approved && x.User.IsActive, cancellationToken)
            ?? throw new NotFoundException("DOCTOR_PROFILE_NOT_FOUND");

        // Validate time
        if (request.ScheduledAt <= DateTime.UtcNow)
            throw new BadRequestException("APPOINTMENT_MUST_BE_IN_FUTURE");

        if (request.ScheduledAt.Second != 0 || request.ScheduledAt.Millisecond != 0 || request.ScheduledAt.Minute % 30 != 0)
            throw new BadRequestException("APPOINTMENT_SLOTS_30_MINUTES");

        // Validate availability
        var isInsideAvailabilityWindow = await _dbContext.DoctorAvailabilities
            .AsNoTracking()
            .AnyAsync(x => x.DoctorProfileId == request.DoctorProfileId &&
                           x.IsActive &&
                           x.DayOfWeek == request.ScheduledAt.DayOfWeek &&
                           x.StartTime <= request.ScheduledAt.TimeOfDay &&
                           request.ScheduledAt.TimeOfDay < x.EndTime,
                cancellationToken);
        if (!isInsideAvailabilityWindow)
            throw new BadRequestException("TIME_OUTSIDE_AVAILABILITY");

        // Check for overlapping appointment
        var overlapping = await _dbContext.Appointments.AnyAsync(
            x => x.DoctorProfileId == request.DoctorProfileId &&
                 x.ScheduledAt == request.ScheduledAt &&
                 x.Status != AppointmentStatus.Cancelled,
            cancellationToken);
        if (overlapping)
            throw new BadRequestException("SLOT_ALREADY_BOOKED");

        // Calculate fees
        var consultationFee = doctorProfile.ConsultationFee;
        var commissionPercent = _configuration.GetValue<decimal>("Paymob:CommissionPercent", 10);
        var platformFee = Math.Round(consultationFee * commissionPercent / 100, 2);
        var total = consultationFee;

        // Get patient info for billing
        var patient = await _dbContext.Users
            .AsNoTracking()
            .FirstAsync(x => x.Id == request.UserId, cancellationToken);

        // ─── Cash (Pay at Clinic) ───
        if (request.PaymentMethod == PaymentMethod.Cash)
        {
            var appointment = new Appointment
            {
                PatientId = request.UserId,
                DoctorProfileId = request.DoctorProfileId,
                ScheduledAt = request.ScheduledAt,
                LocationName = string.IsNullOrWhiteSpace(request.LocationName) ? doctorProfile.ClinicName : request.LocationName.Trim(),
                Status = AppointmentStatus.PendingPayment,
                PaymentStatus = PaymentStatus.Unpaid,
                PaymentMethod = PaymentMethod.Cash,
                AmountPaid = total
            };

            _dbContext.Appointments.Add(appointment);
            await _dbContext.SaveChangesAsync(cancellationToken);

            // Notify doctor about pending cash appointment
            await _notificationService.SendToUserAsync(
                doctorProfile.UserId,
                "New appointment request",
                $"A patient wants to book (Pay at Clinic) on {appointment.ScheduledAt:MMM dd 'at' hh:mm tt}. Please approve or reject.",
                new Dictionary<string, string>
                {
                    ["type"] = NotificationTypes.AppointmentBooked,
                    ["referenceId"] = appointment.Id.ToString()
                },
                cancellationToken);

            return Result.Success(
                new InitiatePaymentResult(appointment.Id, null, null, null, consultationFee, platformFee, total, false),
                "CASH_APPOINTMENT_CREATED_SUCCESS");
        }

        // ─── Online Payment (Card/Wallet) ───
        var integrationId = request.PaymentMethod == PaymentMethod.Card
            ? _configuration.GetValue<int>("Paymob:CardIntegrationId")
            : _configuration.GetValue<int>("Paymob:WalletIntegrationId");

        if (integrationId <= 0)
        {
            throw new BadRequestException(request.PaymentMethod == PaymentMethod.Card
                ? "CARD_PAYMENT_NOT_CONFIGURED"
                : "WALLET_PAYMENT_NOT_CONFIGURED");
        }

        var iframeId = _configuration.GetValue<int>("Paymob:IframeId");
        if (iframeId <= 0)
        {
            throw new BadRequestException("ONLINE_PAYMENTS_NOT_CONFIGURED");
        }
        // Wallet requires a phone number
        if (request.PaymentMethod == PaymentMethod.Wallet &&
            string.IsNullOrWhiteSpace(request.WalletPhone))
            throw new BadRequestException("WALLET_PHONE_REQUIRED");

        var amountCents = (int)(total * 100);
        var merchantOrderId = $"FYC-{Guid.NewGuid():N}";

        // Paymob 3-step flow
        var authToken = await _paymobService.AuthenticateAsync();
        var paymobOrderId = await _paymobService.CreateOrderAsync(authToken, amountCents, merchantOrderId);
        var paymentKey = await _paymobService.GeneratePaymentKeyAsync(
            authToken,
            paymobOrderId,
            amountCents,
            integrationId,
            new PaymobBillingData(
                patient.FirstName ?? "N/A",
                patient.LastName ?? "N/A",
                patient.Email ?? "na@email.com",
                patient.PhoneNumber ?? "N/A"));

        // Persist a pending intent so the webhook can finalize the booking
        // even if the client never reaches ConfirmPayment (app killed, no network).
        var doctorEarnings = consultationFee - platformFee;
        var intent = new PendingBookingIntent
        {
            PaymobOrderId = paymobOrderId,
            MerchantOrderId = merchantOrderId,
            PatientId = request.UserId,
            DoctorProfileId = request.DoctorProfileId,
            ScheduledAt = request.ScheduledAt,
            LocationName = string.IsNullOrWhiteSpace(request.LocationName)
                ? doctorProfile.ClinicName
                : request.LocationName.Trim(),
            Amount = consultationFee,
            PlatformFee = platformFee,
            DoctorEarnings = doctorEarnings,
            PaymentMethod = request.PaymentMethod,
            ExpiresAt = DateTime.UtcNow.AddHours(1)
        };
        _dbContext.PendingBookingIntents.Add(intent);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // ─── Wallet: call Paymob's wallet pay API → get redirect URL ───
        if (request.PaymentMethod == PaymentMethod.Wallet)
        {
            var redirectUrl = await _paymobService.InitiateWalletPayAsync(paymentKey, request.WalletPhone!.Trim());
            return Result.Success(
                new InitiatePaymentResult(null, paymentKey, paymobOrderId, null, consultationFee, platformFee, total, true, redirectUrl),
                "WALLET_PAYMENT_INITIATED_SUCCESS");
        }

        // ─── Card: standard iframe flow ───
        return Result.Success(
            new InitiatePaymentResult(null, paymentKey, paymobOrderId, iframeId, consultationFee, platformFee, total, true),
            "CARD_PAYMENT_INITIATED_SUCCESS");
    }
}
