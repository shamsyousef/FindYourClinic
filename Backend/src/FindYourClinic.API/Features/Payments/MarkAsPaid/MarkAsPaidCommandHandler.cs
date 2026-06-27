using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Controllers;

public class MarkAsPaidCommandHandler : IRequestHandler<MarkAsPaidCommand, ApiResponse<string>>
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IConfiguration _configuration;

    public MarkAsPaidCommandHandler(ApplicationDbContext dbContext, IConfiguration configuration)
    {
        _dbContext = dbContext;
        _configuration = configuration;
    }

    public async Task<ApiResponse<string>> Handle(MarkAsPaidCommand request, CancellationToken cancellationToken)
    {
        if (request.Role != UserRole.Doctor)
            throw new ForbiddenException("Only doctors can mark appointments as paid.");

        var appointment = await _dbContext.Appointments
            .Include(x => x.DoctorProfile)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, cancellationToken)
            ?? throw new NotFoundException("Appointment not found.");

        if (appointment.DoctorProfile.UserId != request.UserId)
            throw new ForbiddenException("You can only manage your own appointments.");

        if (appointment.PaymentMethod != PaymentMethod.Cash)
            throw new BadRequestException("Only cash appointments can be marked as paid.");

        if (appointment.PaymentStatus == PaymentStatus.Paid)
            throw new BadRequestException("Appointment is already marked as paid.");

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

        return ApiResponse<string>.Ok("Paid", "Appointment marked as paid.");
    }
}
