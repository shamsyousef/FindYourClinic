using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.Infrastructure.BackgroundJobs;

public class AppointmentAutoCompleteService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<AppointmentAutoCompleteService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan AppointmentDuration = TimeSpan.FromMinutes(30);

    public AppointmentAutoCompleteService(
        IServiceScopeFactory scopeFactory,
        ILogger<AppointmentAutoCompleteService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Appointment auto-complete service started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessExpiredAppointmentsAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed while processing expired appointments.");
            }

            try
            {
                await Task.Delay(Interval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    private async Task ProcessExpiredAppointmentsAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        var cutoff = DateTime.UtcNow - AppointmentDuration;

        // Auto-complete: Confirmed appointments whose time has fully passed
        var toComplete = await context.Appointments
            .Where(x => x.Status == AppointmentStatus.Confirmed &&
                        x.ScheduledAt <= cutoff)
            .ToListAsync(cancellationToken);

        foreach (var apt in toComplete)
        {
            apt.Status = AppointmentStatus.Completed;

            try
            {
                await notificationService.SendToUserAsync(
                    apt.PatientId,
                    "Appointment completed",
                    "Your appointment has been automatically marked as completed.",
                    new Dictionary<string, string>
                    {
                        ["type"] = NotificationTypes.AppointmentCompleted,
                        ["referenceId"] = apt.Id.ToString()
                    },
                    cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send completion notification for appointment {Id}", apt.Id);
            }
        }

        // Auto-cancel: Scheduled (unconfirmed) appointments whose time has passed
        var toCancel = await context.Appointments
            .Where(x => x.Status == AppointmentStatus.Scheduled &&
                        x.ScheduledAt <= cutoff)
            .ToListAsync(cancellationToken);

        foreach (var apt in toCancel)
        {
            apt.Status = AppointmentStatus.Cancelled;

            try
            {
                await notificationService.SendToUserAsync(
                    apt.PatientId,
                    "Appointment cancelled",
                    "Your appointment was automatically cancelled because it was not confirmed in time.",
                    new Dictionary<string, string>
                    {
                        ["type"] = NotificationTypes.AppointmentCancelled,
                        ["referenceId"] = apt.Id.ToString()
                    },
                    cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send cancellation notification for appointment {Id}", apt.Id);
            }
        }

        if (toComplete.Count + toCancel.Count > 0)
        {
            await context.SaveChangesAsync(cancellationToken);
            _logger.LogInformation(
                "Auto-processed {Completed} completed and {Cancelled} cancelled appointments.",
                toComplete.Count, toCancel.Count);
        }
    }
}
