using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.Infrastructure.BackgroundJobs;

public class AppointmentReminderService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<AppointmentReminderService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(15);

    public AppointmentReminderService(IServiceScopeFactory scopeFactory, ILogger<AppointmentReminderService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Appointment reminder service started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await SendRemindersAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed while processing appointment reminders.");
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

    private async Task SendRemindersAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var localizer = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Localization.IStringLocalizer<FindYourClinic.Domain.Resources.SharedResource>>();
        var now = DateTime.UtcNow;
        var reminderWindow = now.AddHours(1);

        var appointments = await context.Appointments
          .Include(x => x.DoctorProfile).ThenInclude(x => x.User)
          .Include(x => x.Patient)
          .Where(x => x.Status == AppointmentStatus.Confirmed &&
                      x.ScheduledAt >= now &&
                      x.ScheduledAt <= reminderWindow &&
                      !x.ReminderSent)
          .ToListAsync(cancellationToken);

        foreach (var appointment in appointments)
        {
            var doctorName = $"{appointment.DoctorProfile.User.FirstName} {appointment.DoctorProfile.User.LastName}".Trim();
            using (new FindYourClinic.Domain.Resources.CultureScope(appointment.Patient.PreferredLanguage))
            {
                var title = localizer["Notification.Appointment.Reminder.Title"] ?? "Upcoming appointment";
                var bodyTemplate = localizer["Notification.Appointment.Reminder.Body"] ?? "Reminder: You have an appointment with Dr. {0} in about 1 hour.";
                var body = string.Format(bodyTemplate, doctorName);

                await notificationService.SendToUserAsync(
                    appointment.PatientId,
                    title,
                    body,
                    new Dictionary<string, string>
                    {
                        ["type"] = NotificationTypes.AppointmentReminder,
                        ["referenceId"] = appointment.Id.ToString()
                    },
                    cancellationToken);
            }

            appointment.ReminderSent = true;
        }

        if (appointments.Count > 0)
        {
            await context.SaveChangesAsync(cancellationToken);
        }
    }
}
