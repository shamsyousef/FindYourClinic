using FindYourClinic.API.Services;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Payments.InitiatePayment;

public class InitiatePaymentCommandHandler : IRequestHandler<InitiatePaymentCommand, ApiResponse<InitiatePaymentResult>>
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

    public async Task<ApiResponse<InitiatePaymentResult>> Handle(InitiatePaymentCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Patient)
            throw new ForbiddenException("Only patients can book appointments.");

        // Validate doctor
        var doctorProfile = await _dbContext.DoctorProfiles
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == request.DoctorProfileId && x.Status == DoctorStatus.Approved && x.User.IsActive, cancellationToken)
            ?? throw new NotFoundException("Doctor profile not found.");

        // Validate time
        if (request.ScheduledAt <= DateTime.UtcNow)
            throw new BadRequestException("Appointment must be in the future.");

        if (request.ScheduledAt.Second != 0 || request.ScheduledAt.Millisecond != 0 || request.ScheduledAt.Minute % 30 != 0)
            throw new BadRequestException("Appointments must be booked on 30-minute slots.");

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
            throw new BadRequestException("Selected time is outside doctor availability.");

        // Check for overlapping appointment
        var overlapping = await _dbContext.Appointments.AnyAsync(
            x => x.DoctorProfileId == request.DoctorProfileId &&
                 x.ScheduledAt == request.ScheduledAt &&
                 x.Status != AppointmentStatus.Cancelled,
            cancellationToken);
        if (overlapping)
            throw new BadRequestException("The selected slot is already booked.");

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

            return ApiResponse<InitiatePaymentResult>.Ok(
                new InitiatePaymentResult(appointment.Id, null, null, null, consultationFee, platformFee, total, false),
                "Cash appointment created. Waiting for doctor approval.");
        }

        // ─── Online Payment (Card/Wallet) ───
        var integrationId = request.PaymentMethod == PaymentMethod.Card
            ? _configuration.GetValue<int>("Paymob:CardIntegrationId")
            : _configuration.GetValue<int>("Paymob:WalletIntegrationId");

        if (integrationId <= 0)
        {
            throw new BadRequestException(request.PaymentMethod == PaymentMethod.Card
                ? "Card payments are not configured yet. Please use Cash or Mobile Wallet."
                : "Wallet payments are not configured yet. Please contact support.");
        }

        var iframeId = _configuration.GetValue<int>("Paymob:IframeId");
        if (iframeId <= 0)
        {
            throw new BadRequestException("Online payments are not configured yet.");
        }
        // Wallet requires a phone number
        if (request.PaymentMethod == PaymentMethod.Wallet &&
            string.IsNullOrWhiteSpace(request.WalletPhone))
            throw new BadRequestException("Wallet phone number is required for mobile wallet payments.");

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
            return ApiResponse<InitiatePaymentResult>.Ok(
                new InitiatePaymentResult(null, paymentKey, paymobOrderId, null, consultationFee, platformFee, total, true, redirectUrl),
                "Wallet payment initiated. Complete payment via your wallet app.");
        }

        // ─── Card: standard iframe flow ───
        return ApiResponse<InitiatePaymentResult>.Ok(
            new InitiatePaymentResult(null, paymentKey, paymobOrderId, iframeId, consultationFee, platformFee, total, true),
            "Payment key generated. Proceed to payment.");
    }
}
