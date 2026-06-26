using System.Text.Json;
using Microsoft.Extensions.Hosting;

namespace FindYourClinic.API.Localization;

public class TranslationService : ITranslationService
{
    private readonly IHostEnvironment _hostEnvironment;

    public TranslationService(IHostEnvironment hostEnvironment)
    {
        _hostEnvironment = hostEnvironment;
    }

    public async Task<Dictionary<string, string>> LoadTranslationsAsync(string languageCode)
    {
        var filePath = Path.Combine(_hostEnvironment.ContentRootPath, "Localization", $"{languageCode}.json");
        
        if (!File.Exists(filePath))
        {
            filePath = Path.Combine(AppContext.BaseDirectory, "Localization", $"{languageCode}.json");
        }

        if (!File.Exists(filePath))
        {
            filePath = Path.Combine(_hostEnvironment.ContentRootPath, "Localization", "en.json");
            if (!File.Exists(filePath))
            {
                filePath = Path.Combine(AppContext.BaseDirectory, "Localization", "en.json");
            }
        }

        if (!File.Exists(filePath))
        {
            return new Dictionary<string, string>();
        }

        try
        {
            var json = await File.ReadAllTextAsync(filePath);
            var translations = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
            return translations ?? new Dictionary<string, string>();
        }
        catch
        {
            return new Dictionary<string, string>();
        }
    }
}
