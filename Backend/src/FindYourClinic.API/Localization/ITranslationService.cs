namespace FindYourClinic.API.Localization;

public interface ITranslationService
{
    Task<Dictionary<string, string>> LoadTranslationsAsync(string languageCode);
}
