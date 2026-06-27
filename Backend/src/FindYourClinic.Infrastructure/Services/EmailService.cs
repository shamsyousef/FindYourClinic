using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Resources;
using FindYourClinic.Infrastructure.Options;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Options;
using MimeKit;

namespace FindYourClinic.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public EmailService(IOptions<EmailSettings> settings, IStringLocalizer<SharedResource> localizer)
    {
        _settings = settings.Value;
        _localizer = localizer;
    }

    public Task SendPasswordResetEmailAsync(string toEmail, string resetLink)
    {
        var subject = _localizer["Email.PasswordReset.Subject"];
        var body = $@"
<div style=""font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;"">
    <h2 style=""color: #333; text-align: center;"">Password Reset Request</h2>
    <p style=""color: #555; font-size: 16px;"">We received a request to reset the password for your Find Your Clinic account. You can reset your password by clicking the button below:</p>
    <div style=""text-align: center; margin: 30px 0;"">
        <a href=""{resetLink}"" style=""background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold; display: inline-block;"">Click here to reset password</a>
    </div>
    <p style=""color: #777; font-size: 14px;"">If you did not request a password reset, please ignore this email.</p>
</div>";
        return SendEmailAsync(toEmail, subject, body, true);
    }

    public Task SendDoctorApprovedEmailAsync(string toEmail, string doctorName)
    {
        var subject = _localizer["Email.DoctorApproved.Subject"];
        var body = $"Hello {doctorName}, your account has been approved. You can now login.";
        return SendEmailAsync(toEmail, subject, body, true);
    }

    public Task SendDoctorRejectedEmailAsync(string toEmail, string doctorName, string reason)
    {
        var body = $"Hello {doctorName}, your account was rejected. Reason: {reason}";
        return SendEmailAsync(toEmail, "Doctor Account Rejected", body);
    }

    public Task SendDoctorActivatedEmailAsync(string toEmail, string doctorName)
    {
        var body = $"Hello {doctorName}, your Find Your Clinic account has been activated. You can now receive appointments.";
        return SendEmailAsync(toEmail, "Your Find Your Clinic account has been activated", body);
    }

    public Task SendDoctorDeactivatedEmailAsync(string toEmail, string doctorName)
    {
        var body = $"Hello {doctorName}, your Find Your Clinic account has been deactivated by an administrator. Please contact support for more information.";
        return SendEmailAsync(toEmail, "Your Find Your Clinic account has been deactivated", body);
    }

    public Task SendDoctorDeletedEmailAsync(string toEmail, string doctorName, string reason)
    {
        var body = $"Hello {doctorName}, your Find Your Clinic account has been deleted by an administrator. Reason: {reason}";
        return SendEmailAsync(toEmail, "Your Find Your Clinic account has been deleted", body);
    }

    public Task SendPatientActivatedEmailAsync(string toEmail, string patientName)
    {
        var body = $"Hello {patientName}, your Find Your Clinic account has been activated. You can now book appointments.";
        return SendEmailAsync(toEmail, "Your Find Your Clinic account has been activated", body);
    }

    public Task SendPatientDeactivatedEmailAsync(string toEmail, string patientName)
    {
        var body = $"Hello {patientName}, your Find Your Clinic account has been deactivated by an administrator. Please contact support for more information.";
        return SendEmailAsync(toEmail, "Your Find Your Clinic account has been deactivated", body);
    }

    public Task SendPatientDeletedEmailAsync(string toEmail, string patientName, string reason)
    {
        var body = $"Hello {patientName}, your Find Your Clinic account has been deleted by an administrator. Reason: {reason}";
        return SendEmailAsync(toEmail, "Your Find Your Clinic account has been deleted", body);
    }

    private async Task SendEmailAsync(string toEmail, string subject, string body, bool isHtml = false)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_settings.FromName, _settings.Username));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = subject;
        message.Body = new TextPart(isHtml ? "html" : "plain") { Text = body };

        using var client = new SmtpClient();
        client.ServerCertificateValidationCallback = (s, c, h, e) => true;
        await client.ConnectAsync(_settings.Host, _settings.Port, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(_settings.Username, _settings.Password);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}