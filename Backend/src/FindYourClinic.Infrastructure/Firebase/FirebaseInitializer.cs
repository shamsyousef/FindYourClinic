using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.Infrastructure.Firebase;

public static class FirebaseInitializer
{
    private static bool _initialized;

    public static void Initialize(IConfiguration configuration, ILogger logger)
    {
        if (_initialized || FirebaseApp.DefaultInstance is not null)
        {
            _initialized = true;
            return;
        }

        try
        {
            var credentialJson = configuration["Firebase:CredentialJson"];
            var credentialPath = configuration["Firebase:CredentialPath"] ?? "firebase-adminsdk.json";

            GoogleCredential? credential = null;
            if (!string.IsNullOrWhiteSpace(credentialJson))
            {
                credential = GoogleCredential.FromJson(credentialJson);
                logger.LogInformation("Firebase initialized from credential json.");
            }
            else if (File.Exists(credentialPath))
            {
                credential = GoogleCredential.FromFile(credentialPath);
                logger.LogInformation("Firebase initialized from credential file path {Path}.", credentialPath);
            }

            if (credential is null)
            {
                logger.LogWarning("Firebase credentials not found. Push notifications are disabled.");
                return;
            }

            FirebaseApp.Create(new AppOptions { Credential = credential });
            _initialized = true;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to initialize Firebase. Push notifications are disabled.");
        }
    }
}
