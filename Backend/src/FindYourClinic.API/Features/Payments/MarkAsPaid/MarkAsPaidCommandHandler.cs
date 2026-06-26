using Ardalis.Result;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Controllers;

public class MarkAsPaidCommandHandler : IRequestHandler<MarkAsPaidCommand, Result<string>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IConfiguration _configuration;

    public MarkAsPaidCommandHandler(ApplicationDbContext dbContext, IConfiguration configuration)
    {
        _dbContext = dbContext;
        _configuration = configuration;
    }

    public async Task<Result<string>> Handle(MarkAsPaidCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("ONLY_DOCTORS_CAN_MARK_PAID");

        var appointment = await _dbContext.Appointments
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("APPOINTMENT_NOT_FOUND");

        if (appointment.DoctorProfile.UserId != request.UserId)
            throw new ForbiddenException("MANAGE_OWN_APPOINTMENTS_ONLY");

        if (appointment.PaymentMethod != PaymentMethod.Cash)
            throw new BadRequestException("ONLY_CASH_APPOINTMENTS_MARKED_PAID");

        if (appointment.PaymentStatus == PaymentStatus.Paid)
            throw new BadRequestException("APPOINTMENT_ALREADY_MARKED_PAID");

        // Calculate fees
        var consultationFee = appointment.DoctorProfile.ConsultationFee;
        var commissionPercent = _configuration.GetValue<decimal>("Paymob:CommissionPercent", 10);
        var platformFee = Math.Round(consultationFee * commissionPercent / 100, 2);
        var doctorEarnings = consultationFee - platformFee;

        appointment.PaymentStatus = PaymentStatus.Paid;

        // Create transaction for cash payment
        var transaction = new Transaction
        {
            AppointmentId = appointment.Id,
            PatientId = appointment.PatientId,
            DoctorProfileId = appointment.DoctorProfileId,
            Amount = consultationFee,
            PlatformFee = platformFee,
            DoctorEarnings = doctorEarnings,
            PaymentMethod = PaymentMethod.Cash,
            Status = PaymentStatus.Paid,
            CompletedAt = DateTime.UtcNow
        };

        _dbContext.Transactions.Add(transaction);

        // Update wallet
        var wallet = await _dbContext.DoctorWallets
            .FirstOrDefaultAsync(x => x.DoctorProfileId == appointment.DoctorProfileId, cancellationToken);

        if (wallet is null)
        {
            wallet = new DoctorWallet
            {
                DoctorProfileId = appointment.DoctorProfileId,
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

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Result.Success("Paid", "APPOINTMENT_MARKED_PAID_SUCCESS");
    }
}
