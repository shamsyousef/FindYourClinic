using System.Security.Claims;
using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace FindYourClinic.Infrastructure.Persistence;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>
{
    private readonly IHttpContextAccessor? _httpContextAccessor;

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options, IHttpContextAccessor? httpContextAccessor = null)
        : base(options)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public DbSet<DoctorProfile> DoctorProfiles => Set<DoctorProfile>();
    public DbSet<Specialty> Specialties => Set<Specialty>();
    public DbSet<DoctorDocument> DoctorDocuments => Set<DoctorDocument>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<Appointment> Appointments => Set<Appointment>();
    public DbSet<DoctorAvailability> DoctorAvailabilities => Set<DoctorAvailability>();
    public DbSet<HealthRecord> HealthRecords => Set<HealthRecord>();
    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<MessageReaction> MessageReactions => Set<MessageReaction>();
    public DbSet<DoctorReview> DoctorReviews => Set<DoctorReview>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AiChatMessage> AiChatMessages => Set<AiChatMessage>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<DoctorWallet> DoctorWallets => Set<DoctorWallet>();
    public DbSet<PendingBookingIntent> PendingBookingIntents => Set<PendingBookingIntent>();
    public DbSet<DoctorPaymentInfo> DoctorPaymentInfos => Set<DoctorPaymentInfo>();

    // EF Core reads DateTime from SQL Server as DateTimeKind.Unspecified.
    // This convention marks every DateTime property as UTC on read so that
    // System.Text.Json serialises them with the trailing 'Z', fixing the
    // 3-hour offset clients see when they're in a UTC+ timezone.
    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        configurationBuilder.Properties<DateTime>()
            .HaveConversion<UtcDateTimeConverter>();
        configurationBuilder.Properties<DateTime?>()
            .HaveConversion<UtcNullableDateTimeConverter>();
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<ApplicationUser>(entity =>
        {
            entity.Property(x => x.FirstName).HasMaxLength(100);
            entity.Property(x => x.LastName).HasMaxLength(100);
            entity.Property(x => x.ProfileImageUrl).HasMaxLength(500);
            entity.Property(x => x.CloudinaryPublicId).HasMaxLength(200);
            entity.Property(x => x.FcmToken).HasMaxLength(512);
            entity.Property(x => x.Gender).HasMaxLength(50);
            entity.Property(x => x.BloodType).HasMaxLength(10);
            entity.Property(x => x.Address).HasMaxLength(500);
            entity.Property(x => x.EmergencyContactName).HasMaxLength(150);
            entity.Property(x => x.EmergencyContactPhone).HasMaxLength(30);
            entity.HasIndex(x => x.Email).IsUnique();
        });

        builder.Entity<DoctorProfile>(entity =>
        {
            entity.Property(x => x.ClinicName).HasMaxLength(200);
            entity.Property(x => x.ClinicAddress).HasMaxLength(500);
            entity.Property(x => x.ConsultationFee).HasColumnType("decimal(18,2)");
            entity.Property(x => x.Bio).HasMaxLength(2000);
            entity.Property(x => x.RejectionReason).HasMaxLength(1000);
            entity.HasOne(x => x.User)
                .WithOne(x => x.DoctorProfile)
                .HasForeignKey<DoctorProfile>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Specialty)
                .WithMany(x => x.DoctorProfiles)
                .HasForeignKey(x => x.SpecialtyId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.SpecialtyId);
        });

        builder.Entity<Specialty>(entity =>
        {
            entity.Property(x => x.Name).HasMaxLength(100).IsRequired();
            entity.Property(x => x.IconUrl).HasMaxLength(1000);
            entity.HasIndex(x => x.Name).IsUnique();
        });

        builder.Entity<DoctorDocument>(entity =>
        {
            entity.Property(x => x.DocumentType).HasMaxLength(100).IsRequired();
            entity.Property(x => x.FileUrl).HasMaxLength(1000).IsRequired();
            entity.Property(x => x.CloudinaryPublicId).HasMaxLength(500).IsRequired();
            entity.HasOne(x => x.DoctorProfile)
                .WithMany(x => x.Documents)
                .HasForeignKey(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<RefreshToken>(entity =>
        {
            entity.Property(x => x.Token).HasMaxLength(500).IsRequired();
            entity.HasIndex(x => x.Token).IsUnique();
            entity.HasOne(x => x.User)
                .WithMany(x => x.RefreshTokens)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<PasswordResetToken>(entity =>
        {
            entity.Property(x => x.Token).HasMaxLength(500).IsRequired();
            entity.HasIndex(x => x.Token).IsUnique();
            entity.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<Appointment>(entity =>
        {
            entity.Property(x => x.LocationName).HasMaxLength(500);
            entity.Property(x => x.AmountPaid).HasColumnType("decimal(18,2)");
            entity.Property(x => x.PaymobOrderId).HasMaxLength(200);
            entity.Property(x => x.PaymobTransactionId).HasMaxLength(200);
            entity.HasOne(x => x.Patient)
                .WithMany(x => x.PatientAppointments)
                .HasForeignKey(x => x.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.DoctorProfile)
                .WithMany(x => x.Appointments)
                .HasForeignKey(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.DoctorProfileId, x.ScheduledAt });
            entity.HasIndex(x => new { x.PatientId, x.ScheduledAt });
            entity.HasIndex(x => new { x.Status, x.ScheduledAt, x.ReminderSent });
        });

        builder.Entity<DoctorAvailability>(entity =>
        {
            entity.HasOne(x => x.DoctorProfile)
                .WithMany(x => x.Availabilities)
                .HasForeignKey(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.DoctorProfileId, x.DayOfWeek, x.IsActive });
        });

        builder.Entity<HealthRecord>(entity =>
        {
            entity.Property(x => x.Title).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Value).HasMaxLength(300);
            entity.Property(x => x.Notes).HasMaxLength(2000);
            entity.HasOne(x => x.Patient)
                .WithMany(x => x.HealthRecords)
                .HasForeignKey(x => x.PatientId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.PatientId, x.RecordedAt });
        });

        builder.Entity<Conversation>(entity =>
        {
            entity.HasOne(x => x.Patient)
                .WithMany(x => x.PatientConversations)
                .HasForeignKey(x => x.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Doctor)
                .WithMany(x => x.DoctorConversations)
                .HasForeignKey(x => x.DoctorId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.PatientId, x.DoctorId }).IsUnique();
        });

        builder.Entity<ChatMessage>(entity =>
        {
            entity.Property(x => x.Content).HasMaxLength(3000);
            entity.Property(x => x.MediaUrl).HasMaxLength(1000);
            entity.Property(x => x.MediaThumbnailUrl).HasMaxLength(1000);
            entity.Property(x => x.Type).HasConversion<int>();
            entity.HasOne(x => x.Conversation)
                .WithMany(x => x.Messages)
                .HasForeignKey(x => x.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Sender)
                .WithMany(x => x.SentMessages)
                .HasForeignKey(x => x.SenderId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.ReplyToMessage)
                .WithMany()
                .HasForeignKey(x => x.ReplyToMessageId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.ConversationId, x.SentAt });
        });

        builder.Entity<MessageReaction>(entity =>
        {
            entity.Property(x => x.Emoji).HasMaxLength(16).IsRequired();
            entity.HasOne(x => x.Message)
                .WithMany(x => x.Reactions)
                .HasForeignKey(x => x.MessageId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.MessageId, x.UserId, x.Emoji }).IsUnique();
        });

        builder.Entity<DoctorReview>(entity =>
        {
            entity.Property(x => x.Comment).HasMaxLength(2000);
            entity.HasOne(x => x.DoctorProfile)
                .WithMany(x => x.Reviews)
                .HasForeignKey(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Patient)
                .WithMany(x => x.DoctorReviews)
                .HasForeignKey(x => x.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.DoctorProfileId, x.CreatedAt });
            entity.HasIndex(x => new { x.PatientId, x.DoctorProfileId }).IsUnique();
        });

        builder.Entity<Notification>(entity =>
        {
            entity.Property(x => x.Title).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Body).HasMaxLength(2000).IsRequired();
            entity.Property(x => x.Type).HasMaxLength(100);
            entity.Property(x => x.ReferenceId).HasMaxLength(200);
            entity.HasOne(x => x.User)
                .WithMany(x => x.Notifications)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt });
            entity.HasIndex(x => new { x.UserId, x.IsRead });
        });

        builder.Entity<AiChatMessage>(entity =>
        {
            entity.Property(x => x.UserId).HasMaxLength(450).IsRequired();
            entity.Property(x => x.Role).HasMaxLength(20).IsRequired();
            entity.Property(x => x.Content).HasMaxLength(8000).IsRequired();
            entity.HasIndex(x => new { x.UserId, x.CreatedAt });
        });

        builder.Entity<Transaction>(entity =>
        {
            entity.Property(x => x.Amount).HasColumnType("decimal(18,2)");
            entity.Property(x => x.PlatformFee).HasColumnType("decimal(18,2)");
            entity.Property(x => x.DoctorEarnings).HasColumnType("decimal(18,2)");
            entity.Property(x => x.PaymobOrderId).HasMaxLength(200);
            entity.Property(x => x.PaymobTransactionId).HasMaxLength(200);
            entity.HasOne(x => x.Appointment)
                .WithOne(x => x.Transaction)
                .HasForeignKey<Transaction>(x => x.AppointmentId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Patient)
                .WithMany()
                .HasForeignKey(x => x.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.DoctorProfile)
                .WithMany(x => x.Transactions)
                .HasForeignKey(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.PaymobOrderId);
            entity.HasIndex(x => new { x.PatientId, x.CreatedAt });
            entity.HasIndex(x => new { x.DoctorProfileId, x.CreatedAt });
        });

        builder.Entity<DoctorWallet>(entity =>
        {
            entity.Property(x => x.TotalEarnings).HasColumnType("decimal(18,2)");
            entity.Property(x => x.PendingBalance).HasColumnType("decimal(18,2)");
            entity.Property(x => x.WithdrawnAmount).HasColumnType("decimal(18,2)");
            entity.HasOne(x => x.DoctorProfile)
                .WithOne(x => x.Wallet)
                .HasForeignKey<DoctorWallet>(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<PendingBookingIntent>(entity =>
        {
            entity.Property(x => x.PaymobOrderId).HasMaxLength(200).IsRequired();
            entity.Property(x => x.MerchantOrderId).HasMaxLength(200).IsRequired();
            entity.Property(x => x.LocationName).HasMaxLength(500);
            entity.Property(x => x.Amount).HasColumnType("decimal(18,2)");
            entity.Property(x => x.PlatformFee).HasColumnType("decimal(18,2)");
            entity.Property(x => x.DoctorEarnings).HasColumnType("decimal(18,2)");
            entity.HasIndex(x => x.PaymobOrderId).IsUnique();
            entity.HasIndex(x => new { x.PatientId, x.IsConsumed });
        });

        builder.Entity<DoctorPaymentInfo>(entity =>
        {
            entity.Property(x => x.WalletPhoneNumber).HasMaxLength(20);
            entity.Property(x => x.BankName).HasMaxLength(200);
            entity.Property(x => x.AccountHolderName).HasMaxLength(200);
            entity.Property(x => x.AccountNumber).HasMaxLength(100);
            entity.Property(x => x.IBAN).HasMaxLength(50);
            entity.HasOne(x => x.DoctorProfile)
                .WithOne(x => x.PaymentInfo)
                .HasForeignKey<DoctorPaymentInfo>(x => x.DoctorProfileId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    public override int SaveChanges()
    {
        ApplyAuditInfo();
        return base.SaveChanges();
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        ApplyAuditInfo();
        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        ApplyAuditInfo();
        return base.SaveChangesAsync(cancellationToken);
    }

    public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        ApplyAuditInfo();
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }

    private void ApplyAuditInfo()
    {
        Guid? currentUserId = null;
        var userIdValue = _httpContextAccessor?.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrWhiteSpace(userIdValue) && Guid.TryParse(userIdValue, out var parsedUserId))
        {
            currentUserId = parsedUserId;
        }

        var now = DateTime.UtcNow;
        var auditableEntries = ChangeTracker.Entries()
            .Where(entry => entry.Entity is IAuditableEntity &&
                            entry.State is EntityState.Added or EntityState.Modified);

        foreach (var entry in auditableEntries)
        {
            var auditable = (IAuditableEntity)entry.Entity;

            if (entry.State == EntityState.Added)
            {
                if (auditable.CreatedAt == default)
                {
                    auditable.CreatedAt = now;
                }

                auditable.CreatedBy ??= currentUserId;
            }
            else
            {
                entry.Property(nameof(IAuditableEntity.CreatedAt)).IsModified = false;
                entry.Property(nameof(IAuditableEntity.CreatedBy)).IsModified = false;
            }

            auditable.UpdatedAt = now;
            auditable.UpdatedBy = currentUserId;
        }
    }
}

file sealed class UtcDateTimeConverter()
    : ValueConverter<DateTime, DateTime>(v => v, v => DateTime.SpecifyKind(v, DateTimeKind.Utc));

file sealed class UtcNullableDateTimeConverter()
    : ValueConverter<DateTime?, DateTime?>(v => v, v => v.HasValue ? DateTime.SpecifyKind(v.Value, DateTimeKind.Utc) : null);
