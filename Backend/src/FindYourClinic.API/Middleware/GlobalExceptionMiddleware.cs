using System.Net;
using System.Text.Json;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Exceptions;
using FluentValidation;

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
            context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            await context.Response.WriteAsJsonAsync(new
            {
                type = "https://tools.ietf.org/html/rfc9110#section-15.5.1",
                title = "One or more validation errors occurred.",
                status = 400,
                errors = ex.Errors.GroupBy(x => x.PropertyName)
                    .ToDictionary(x => x.Key, x => x.Select(y => y.ErrorMessage).ToArray())
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception.");
            var (statusCode, message) = MapException(ex);
            context.Response.StatusCode = (int)statusCode;
            context.Response.ContentType = "application/json";

            var payload = ApiResponse<object>.Fail(message);
            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            await context.Response.WriteAsync(JsonSerializer.Serialize(payload, options));
        }
    }

    private static (HttpStatusCode statusCode, string message) MapException(Exception ex)
    {
        return ex switch
        {
            NotFoundException => (HttpStatusCode.NotFound, ex.Message),
            ForbiddenException => (HttpStatusCode.Forbidden, ex.Message),
            UnauthorizedException => (HttpStatusCode.Unauthorized, ex.Message),
            BadRequestException => (HttpStatusCode.BadRequest, ex.Message),
            _ => (HttpStatusCode.InternalServerError, "An unexpected error occurred.")
        };
    }
}
