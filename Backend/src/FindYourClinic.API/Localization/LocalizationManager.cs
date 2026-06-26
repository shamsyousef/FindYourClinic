using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;

namespace FindYourClinic.API.Localization;

public class LocalizationManager : ILocalizationManager
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IMemoryCache _memoryCache;
    private readonly ITranslationService _translationService;
    private static readonly HashSet<string> SupportedLanguages = new(StringComparer.OrdinalIgnoreCase) { "en", "ar" };

    public LocalizationManager(
        IHttpContextAccessor httpContextAccessor,
        IMemoryCache memoryCache,
        ITranslationService translationService)
    {
        _httpContextAccessor = httpContextAccessor;
        _memoryCache = memoryCache;
        _translationService = translationService;
    }

    public async Task PreloadTranslationsAsync(IEnumerable<string> supportedLanguages)
    {
        foreach (var lang in supportedLanguages)
        {
            if (SupportedLanguages.Contains(lang))
            {
                var translations = await _translationService.LoadTranslationsAsync(lang);
                foreach (var kvp in translations)
                {
                    var cacheKey = GetCacheKey(lang, kvp.Key);
                    _memoryCache.Set(cacheKey, kvp.Value);
                }
            }
        }
    }

    public string L(string key)
    {
        if (string.IsNullOrWhiteSpace(key)) return string.Empty;

        var lang = GetRequestLanguage();

        var cacheKey = GetCacheKey(lang, key);
        if (_memoryCache.TryGetValue(cacheKey, out string? value) && value != null)
        {
            return value;
        }

        return key;
    }

    private string GetRequestLanguage()
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null)
        {
            return "en";
        }

        var acceptLanguageHeader = httpContext.Request.Headers["Accept-Language"].ToString();
        if (string.IsNullOrWhiteSpace(acceptLanguageHeader))
        {
            return "en";
        }

        var languages = acceptLanguageHeader.Split(',')
            .Select(x => x.Split(';')[0].Trim())
            .ToList();

        foreach (var rawLang in languages)
        {
            var parsedLang = rawLang;
            var dashIndex = rawLang.IndexOf('-');
            if (dashIndex > 0)
            {
                parsedLang = rawLang.Substring(0, dashIndex);
            }

            parsedLang = parsedLang.ToLowerInvariant();

            if (SupportedLanguages.Contains(parsedLang))
            {
                return parsedLang;
            }
        }

        return "en";
    }

    private string GetCacheKey(string lang, string key)
    {
        return $"{lang.ToLowerInvariant()}_{key}";
    }
}
