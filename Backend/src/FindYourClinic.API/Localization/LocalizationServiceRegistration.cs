using Microsoft.Extensions.DependencyInjection;

namespace FindYourClinic.API.Localization;

public static class LocalizationServiceRegistration
{
    public static IServiceCollection AddApplicationLocalization(this IServiceCollection services)
    {
        services.AddHttpContextAccessor();
        services.AddMemoryCache();
        services.AddSingleton<ITranslationService, TranslationService>();
        services.AddSingleton<ILocalizationManager, LocalizationManager>();

        return services;
    }
}
