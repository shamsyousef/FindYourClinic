using System.Globalization;

namespace FindYourClinic.Domain.Resources;

/// <summary>
/// A disposable scope that temporarily sets the current thread's culture and UI culture.
/// Useful for background tasks (e.g., sending localized emails) where there is no HTTP request.
/// </summary>
public class CultureScope : IDisposable
{
    private readonly CultureInfo _originalCulture;
    private readonly CultureInfo _originalUICulture;

    public CultureScope(string languageCode)
    {
        _originalCulture = CultureInfo.CurrentCulture;
        _originalUICulture = CultureInfo.CurrentUICulture;

        if (!string.IsNullOrWhiteSpace(languageCode))
        {
            try
            {
                var culture = new CultureInfo(languageCode);
                CultureInfo.CurrentCulture = culture;
                CultureInfo.CurrentUICulture = culture;
            }
            catch (CultureNotFoundException)
            {
                // Fallback to default if invalid culture code
            }
        }
    }

    public void Dispose()
    {
        CultureInfo.CurrentCulture = _originalCulture;
        CultureInfo.CurrentUICulture = _originalUICulture;
    }
}
