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
        var body = $"Reset your password using this link: {resetLink}";
        return SendEmailAsync(toEmail, "Reset Your Password", body);
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

    private async Task SendEmailAsync(string toEmail, string subject, string body)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_settings.FromName, _settings.Username));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = subject;
        message.Body = new TextPart("plain") { Text = body };

        using var client = new SmtpClient();
        client.ServerCertificateValidationCallback = (s, c, h, e) => true;
        await client.ConnectAsync(_settings.Host, _settings.Port, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(_settings.Username, _settings.Password);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}
