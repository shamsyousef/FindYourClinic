using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Infrastructure.Options;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace FindYourClinic.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;

    public EmailService(IOptions<EmailSettings> settings)
    {
        _settings = settings.Value;
    }

    public Task SendPasswordResetEmailAsync(string toEmail, string resetLink)
    {
        var body = $"<p>Reset your password using this link:</p><p><a href=\"{resetLink}\">{resetLink}</a></p>";
        return SendEmailAsync(toEmail, "Reset Your Password", body, true);
    }

    public Task SendDoctorApprovedEmailAsync(string toEmail, string doctorName)
    {
        var body = $"Hello {doctorName}, your account has been approved. You can now login.";
        return SendEmailAsync(toEmail, "Doctor Account Approved", body);
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
