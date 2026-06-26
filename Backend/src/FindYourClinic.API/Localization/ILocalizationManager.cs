namespace FindYourClinic.API.Localization;

public interface ILocalizationManager
{
    string L(string key);
    Task PreloadTranslationsAsync(IEnumerable<string> supportedLanguages);
}
