using FindYourClinic.API.Common;
using FindYourClinic.API.Features.Payments.ConfirmPayment;
using FindYourClinic.API.Features.Payments.InitiatePayment;
using FindYourClinic.API.Features.Payments.PaymobWebhook;
using FindYourClinic.API.Localization;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FindYourClinic.API.Controllers;

[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    private readonly IMediator _mediator;

    public PaymentsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Initiate a payment — returns a Paymob payment key for card/wallet, or creates a pending cash appointment.
    /// </summary>
    [HttpPost("initiate")]
    [Authorize]
    public async Task<IActionResult> Initiate([FromBody] InitiatePaymentRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new InitiatePaymentCommand
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            DoctorProfileId = request.DoctorProfileId,
            ScheduledAt = request.ScheduledAt,
            LocationName = request.LocationName,
            PaymentMethod = request.PaymentMethod,
            WalletPhone = request.WalletPhone
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    /// <summary>
    /// Confirm payment after Paymob success — creates the appointment and transaction.
    /// </summary>
    [HttpPost("confirm")]
    [Authorize]
    public async Task<IActionResult> Confirm([FromBody] ConfirmPaymentRequest request, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new ConfirmPaymentCommand
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User),
            DoctorProfileId = request.DoctorProfileId,
            ScheduledAt = request.ScheduledAt,
            LocationName = request.LocationName,
            PaymobOrderId = request.PaymobOrderId,
            PaymobTransactionId = request.PaymobTransactionId,
            PaymentMethod = request.PaymentMethod
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    /// <summary>
    /// Paymob webhook callback — verifies HMAC and processes the transaction.
    /// </summary>
    [HttpPost("webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> Webhook([FromBody] PaymobCallbackData data, [FromQuery] string hmac, CancellationToken cancellationToken)
    {
        var handler = HttpContext.RequestServices.GetRequiredService<PaymobWebhookHandler>();
        await handler.HandleAsync(data, hmac, cancellationToken);
        return Ok();
    }

    /// <summary>
    /// Doctor marks a cash appointment as paid after in-clinic payment.
    /// </summary>
    [HttpPut("{appointmentId:guid}/mark-paid")]
    [Authorize]
    public async Task<IActionResult> MarkAsPaid([FromRoute] Guid appointmentId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new MarkAsPaidCommand
        {
            AppointmentId = appointmentId,
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return this.WriteFromResult(result);
    }

    /// <summary>
    /// Get payment/transaction history for the current user.
    /// </summary>
    [HttpGet("history")]
    [Authorize]
    public async Task<IActionResult> GetHistory(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetPaymentHistoryQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Get doctor earnings/wallet summary.
    /// </summary>
    [HttpGet("earnings")]
    [Authorize]
    public async Task<IActionResult> GetEarnings(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetDoctorEarningsQuery
        {
            UserId = UserContext.GetRequiredUserId(User),
            Role = UserContext.GetRequiredRole(User)
        }, cancellationToken);
        return Ok(result);
    }

    public sealed class InitiatePaymentRequest
    {
        public Guid DoctorProfileId { get; set; }
        public DateTime ScheduledAt { get; set; }
        public string? LocationName { get; set; }
        public PaymentMethod PaymentMethod { get; set; }
        public string? WalletPhone { get; set; }
    }

    public sealed class ConfirmPaymentRequest
    {
        public Guid DoctorProfileId { get; set; }
        public DateTime ScheduledAt { get; set; }
        public string? LocationName { get; set; }
        public string PaymobOrderId { get; set; } = string.Empty;
        public string PaymobTransactionId { get; set; } = string.Empty;
        public PaymentMethod PaymentMethod { get; set; }
    }
}
