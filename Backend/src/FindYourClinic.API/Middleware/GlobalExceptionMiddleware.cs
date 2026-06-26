using System.Net;
using System.Diagnostics;
using FindYourClinic.Domain.Exceptions;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using FindYourClinic.API.Localization;

namespace FindYourClinic.API.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            var localizationManager = context.RequestServices.GetRequiredService<ILocalizationManager>();
            var detail = localizationManager.L("VALIDATION_ERROR");

            var groupedErrors = ex.Errors
                .GroupBy(x => x.PropertyName)
                .ToDictionary(
                    g => string.IsNullOrWhiteSpace(g.Key) ? "General" : g.Key,
                    g => g.Select(y => localizationManager.L(y.ErrorMessage)).ToArray()
                );

            context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            context.Response.ContentType = "application/problem+json";

            await context.Response.WriteAsJsonAsync(new
            {
                type = "https://yourapi.com/errors/validation-error",
                title = "One or more validation errors occurred.",
                status = 400,
                detail = detail,
                success = false,
                traceId = Activity.Current?.Id ?? context.TraceIdentifier,
                code = "VALIDATION_ERROR",
                errors = groupedErrors
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception.");
            var localizationManager = context.RequestServices.GetRequiredService<ILocalizationManager>();
            var (statusCode, defaultTitle, defaultCode) = MapException(ex);

            // Use the exception message as the key, falling back to defaultCode if empty or standard message
            var messageKey = !string.IsNullOrWhiteSpace(ex.Message) && ex.Message != "An unexpected error occurred."
                ? ex.Message 
                : defaultCode;

            var localizedDetail = localizationManager.L(messageKey);

            context.Response.StatusCode = (int)statusCode;
            context.Response.ContentType = "application/problem+json";

            var code = messageKey;

            await context.Response.WriteAsJsonAsync(new
            {
                type = $"https://yourapi.com/errors/{code.ToLowerInvariant().Replace('_', '-')}",
                title = defaultTitle,
                status = (int)statusCode,
                detail = localizedDetail,
                success = false,
                traceId = Activity.Current?.Id ?? context.TraceIdentifier,
                code = code,
                errors = new Dictionary<string, string[]>
                {
                    { "General", new[] { localizedDetail } }
                }
            });
        }
    }

    private static (HttpStatusCode statusCode, string title, string defaultCode) MapException(Exception ex)
    {
        return ex switch
        {
            NotFoundException => (HttpStatusCode.NotFound, "Resource not found", "NOT_FOUND"),
            ForbiddenException => (HttpStatusCode.Forbidden, "Forbidden", "FORBIDDEN"),
            UnauthorizedException => (HttpStatusCode.Unauthorized, "Unauthorized", "UNAUTHORIZED"),
            BadRequestException => (HttpStatusCode.BadRequest, "Bad request", "BUSINESS_RULE"),
            ServiceUnavailableException => (HttpStatusCode.ServiceUnavailable, "Service unavailable", "INTERNAL_ERROR"),
            _ => (HttpStatusCode.InternalServerError, "Internal server error", "INTERNAL_ERROR")
        };
    }
}
