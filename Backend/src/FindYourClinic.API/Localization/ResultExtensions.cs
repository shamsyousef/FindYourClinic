using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using FindYourClinic.Domain.Common;
using Ardalis.Result;

namespace FindYourClinic.API.Localization;

public static class ResultExtensions
{
    public static async Task WriteFromResultAsync(
        this HttpContext context,
        object result)
    {
        var localizationManager =
            context.RequestServices.GetRequiredService<ILocalizationManager>();

        var resultType = result.GetType();

        var isSuccessProp = resultType.GetProperty("Success");
        bool isSuccess = isSuccessProp != null &&
                         (bool)isSuccessProp.GetValue(result)!;


        if (isSuccess)
        {
            var dataProp = resultType.GetProperty("Data");
            var messageProp = resultType.GetProperty("Message");

            var data = dataProp?.GetValue(result);

            var key = messageProp?.GetValue(result)?.ToString();

            context.Response.StatusCode = 200;
            context.Response.ContentType = "application/json";


            await context.Response.WriteAsJsonAsync(new
            {
                success = true,
                message = string.IsNullOrWhiteSpace(key)
                    ? null
                    : localizationManager.L(key),
                data
            });

            return;
        }


        var errorProp = resultType.GetProperty("Message");

        var errorKey = errorProp?.GetValue(result)?.ToString();


        context.Response.StatusCode = 400;
        context.Response.ContentType = "application/problem+json";


        await context.Response.WriteAsJsonAsync(new
        {
            success = false,
            message = localizationManager.L(
                errorKey ?? "INTERNAL_ERROR"
            ),
            traceId = Activity.Current?.Id
                     ?? context.TraceIdentifier
        });
    }



    public static async Task WriteFromResultAsync(
        this ControllerBase controller,
        object result)
    {
        await controller.HttpContext
            .WriteFromResultAsync(result);
    }



    public static IActionResult WriteFromResult(
        this ControllerBase controller,
        object result)
    {
        return new ResultActionResult(result);
    }
}



public class ResultActionResult : IActionResult
{
    private readonly object _result;


    public ResultActionResult(object result)
    {
        _result = result;
    }


    public async Task ExecuteResultAsync(ActionContext context)
    {
        await context.HttpContext
            .WriteFromResultAsync(_result);
    }
}