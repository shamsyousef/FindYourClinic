using System.Net;
using System.Text.Json;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FluentValidation;
using Microsoft.Extensions.Localization;
using FindYourClinic.API.Resources;

namespace FindYourClinic.API.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger, IStringLocalizer<SharedResource> localizer)
    {
        _next = next;
        _logger = logger;
        _localizer = localizer;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            await context.Response.WriteAsJsonAsync(new
            {
                type = "https://tools.ietf.org/html/rfc9110#section-15.5.1",
                title = _localizer["ValidationError"].Value ?? "One or more validation errors occurred.",
                status = 400,
                errors = ex.Errors.GroupBy(x => x.PropertyName)
                    .ToDictionary(x => x.Key, x => x.Select(y => y.ErrorMessage).ToArray())
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception.");
            var (statusCode, messageKey) = MapException(ex);
            var localizedMessage = _localizer[messageKey].Value ?? messageKey;
            context.Response.StatusCode = (int)statusCode;
            context.Response.ContentType = "application/json";

            var payload = ApiResponse<object>.Fail(localizedMessage);
            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            await context.Response.WriteAsync(JsonSerializer.Serialize(payload, options));
        }
    }

    private static (HttpStatusCode statusCode, string messageKey) MapException(Exception ex)
    {
        return ex switch
        {
            NotFoundException => (HttpStatusCode.NotFound, "NotFoundException"),
            ForbiddenException => (HttpStatusCode.Forbidden, "ForbiddenException"),
            UnauthorizedException => (HttpStatusCode.Unauthorized, "UnauthorizedException"),
            BadRequestException => (HttpStatusCode.BadRequest, "BadRequestException"),
            ServiceUnavailableException => (HttpStatusCode.ServiceUnavailable, "ServiceUnavailableException"),
            _ => (HttpStatusCode.InternalServerError, "UnexpectedError")
        };
    }
}