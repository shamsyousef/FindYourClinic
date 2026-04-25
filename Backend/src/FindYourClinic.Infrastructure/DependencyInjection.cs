using System.Text;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Interfaces;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.BackgroundJobs;
using FindYourClinic.Infrastructure.Firebase;
using FindYourClinic.Infrastructure.Options;
using FindYourClinic.Infrastructure.Persistence;
using FindYourClinic.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace FindYourClinic.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddHttpContextAccessor();
        services.Configure<JwtSettings>(configuration.GetSection("JwtSettings"));
        services.Configure<CloudinarySettings>(configuration.GetSection("Cloudinary"));
        services.Configure<GoogleSettings>(configuration.GetSection("Google"));
        services.Configure<EmailSettings>(configuration.GetSection("Email"));
        services.Configure<AppSettings>(configuration.GetSection("AppSettings"));
        services.Configure<AdminSeedSettings>(configuration.GetSection("AdminSeed"));

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
            {
                options.Password.RequiredLength = 8;
                options.Password.RequireDigit = true;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = true;
                options.User.RequireUniqueEmail = true;
            })
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

        var jwtSettings = configuration.GetSection("JwtSettings").Get<JwtSettings>()
            ?? throw new InvalidOperationException("JwtSettings are not configured.");
        var key = Encoding.UTF8.GetBytes(jwtSettings.SecretKey);

        services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidIssuer = jwtSettings.Issuer,
                    ValidAudience = jwtSettings.Audience,
                    ClockSkew = TimeSpan.Zero
                };
            });

        services.AddAuthorization(options =>
        {
            options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
            options.AddPolicy("DoctorOrPendingDoctor", policy =>
            {
                policy.RequireAssertion(context =>
                {
                    var tokenType = context.User.FindFirst("token_type")?.Value;
                    return context.User.IsInRole("Doctor") && (tokenType == "access" || tokenType == "pending_doctor");
                });
            });
        });

        services.AddScoped<IJwtService, JwtService>();
        services.AddScoped<ICloudinaryService, CloudinaryService>();
        services.AddScoped<IGoogleAuthService, GoogleAuthService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddHostedService<AppointmentReminderService>();

        using var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
        var logger = loggerFactory.CreateLogger("FirebaseInitializer");
        FirebaseInitializer.Initialize(configuration, logger);

        return services;
    }
}
