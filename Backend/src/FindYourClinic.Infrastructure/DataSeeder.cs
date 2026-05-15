using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FindYourClinic.Infrastructure;

public static class DataSeeder
{
    private const string Password = "Ahmed@111";
    private const double SadatLat = 30.6167;
    private const double SadatLon = 30.5333;
    private const string SadatAddress = "Sadat City, Monufia, Egypt";

    public static async Task SeedDevelopmentDataAsync(this IServiceProvider serviceProvider)
    {
        var logger = serviceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("DataSeeder");
        var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var db = serviceProvider.GetRequiredService<ApplicationDbContext>();

        logger.LogInformation("Starting development data seeding...");

        var (patient1Id, patient2Id) = await SeedPatientsAsync(userManager, logger);
        await SeedDoctorsAsync(userManager, db, logger);
        await SeedAppointmentsAsync(db, patient1Id, patient2Id, logger);

        logger.LogInformation("Development data seeding completed.");
    }

    private static async Task<(Guid, Guid)> SeedPatientsAsync(
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        var patients = GetPatientData();
        var firstTwoIds = new Guid[2];
        int created = 0;

        for (int i = 0; i < patients.Length; i++)
        {
            var (email, first, last) = patients[i];
            var existing = await userManager.FindByEmailAsync(email);
            Guid userId;

            if (existing is not null)
            {
                userId = existing.Id;
            }
            else
            {
                var user = new ApplicationUser
                {
                    Id = Guid.NewGuid(),
                    UserName = email,
                    Email = email,
                    FirstName = first,
                    LastName = last,
                    Role = UserRole.Patient,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                };

                var result = await userManager.CreateAsync(user, Password);
                if (!result.Succeeded)
                {
                    var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                    logger.LogWarning("Failed to create patient {Email}: {Errors}", email, errors);
                    var found = await userManager.FindByEmailAsync(email);
                    userId = found?.Id ?? Guid.Empty;
                }
                else
                {
                    userId = user.Id;
                    created++;
                }
            }

            if (i < 2) firstTwoIds[i] = userId;
        }

        logger.LogInformation("Seeded {Count} patient(s).", created);
        return (firstTwoIds[0], firstTwoIds[1]);
    }

    private static (string Email, string FirstName, string LastName)[] GetPatientData() =>
    [
        // Original 2 — used for appointment seeding
        ("nourhamdy@gmail.com",     "Nour",    "Hamdy"),
        ("yasminali@gmail.com",     "Yasmin",  "Ali"),

        // 200 additional patients
        ("ahmedsamir@gmail.com",    "Ahmed",   "Samir"),
        ("mohamedhabib@gmail.com",  "Mohamed", "Habib"),
        ("mahmoudosman@gmail.com",  "Mahmoud", "Osman"),
        ("omarsoliman@gmail.com",   "Omar",    "Soliman"),
        ("khaledtawfik@gmail.com",  "Khaled",  "Tawfik"),
        ("tarekwahba@gmail.com",    "Tarek",   "Wahba"),
        ("hassanselim@gmail.com",   "Hassan",  "Selim"),
        ("karimshaker@gmail.com",   "Karim",   "Shaker"),
        ("youssefdiab@gmail.com",   "Youssef", "Diab"),
        ("ibrahimqenawy@gmail.com", "Ibrahim", "Qenawy"),
        ("alizohdy@gmail.com",      "Ali",     "Zohdy"),
        ("mostafashalaby@gmail.com","Mostafa", "Shalaby"),
        ("amrramady@gmail.com",     "Amr",     "Ramady"),
        ("hossamgalal@gmail.com",   "Hossam",  "Galal"),
        ("walidbadr@gmail.com",     "Walid",   "Badr"),
        ("sherifazmy@gmail.com",    "Sherif",  "Azmy"),
        ("aymanlotfy@gmail.com",    "Ayman",   "Lotfy"),
        ("samehgouda@gmail.com",    "Sameh",   "Gouda"),
        ("waelsabry@gmail.com",     "Wael",    "Sabry"),
        ("hazemnassar@gmail.com",   "Hazem",   "Nassar"),
        ("osamahalim@gmail.com",    "Osama",   "Halim"),
        ("tameradly@gmail.com",     "Tamer",   "Adly"),
        ("essamfarag@gmail.com",    "Essam",   "Farag"),
        ("nasseradly@gmail.com",    "Nasser",  "Adly"),
        ("ramyatef@gmail.com",      "Ramy",    "Atef"),
        ("samygaber@gmail.com",     "Samy",    "Gaber"),
        ("ashrafshehata@gmail.com", "Ashraf",  "Shehata"),
        ("adelmorsi@gmail.com",     "Adel",    "Morsi"),
        ("magdyismail@gmail.com",   "Magdy",   "Ismail"),
        ("hanyfawzy@gmail.com",     "Hany",    "Fawzy"),
        ("ramzygad@gmail.com",      "Ramzy",   "Gad"),
        ("gamalamin@gmail.com",     "Gamal",   "Amin"),
        ("hamdisalah@gmail.com",    "Hamdi",   "Salah"),
        ("hatemibrahim@gmail.com",  "Hatem",   "Ibrahim"),
        ("ehabmohamed@gmail.com",   "Ehab",    "Mohamed"),
        ("samirahmed@gmail.com",    "Samir",   "Ahmed"),
        ("nabilhassan@gmail.com",   "Nabil",   "Hassan"),
        ("bassemkhalil@gmail.com",  "Bassem",  "Khalil"),
        ("heshamkamel@gmail.com",   "Hesham",  "Kamel"),
        ("magedrashid@gmail.com",   "Maged",   "Rashid"),
        ("noursamir@gmail.com",     "Nour",    "Samir"),
        ("sarahassan@gmail.com",    "Sara",    "Hassan"),
        ("fatmamohamed@gmail.com",  "Fatma",   "Mohamed"),
        ("ayaibrahim@gmail.com",    "Aya",     "Ibrahim"),
        ("mariamahmed@gmail.com",   "Mariam",  "Ahmed"),
        ("dinamahmoud@gmail.com",   "Dina",    "Mahmoud"),
        ("hanaabdallah@gmail.com",  "Hana",    "Abdallah"),
        ("raniasalem@gmail.com",    "Rania",   "Salem"),
        ("monafarouk@gmail.com",    "Mona",    "Farouk"),
        ("nadiayoussef@gmail.com",  "Nadia",   "Youssef"),
        ("emanahmed@gmail.com",     "Eman",    "Ahmed"),
        ("hebanasser@gmail.com",    "Heba",    "Nasser"),
        ("shimaakamel@gmail.com",   "Shimaa",  "Kamel"),
        ("doaarashid@gmail.com",    "Doaa",    "Rashid"),
        ("amiramansour@gmail.com",  "Amira",   "Mansour"),
        ("rehamibrahim@gmail.com",  "Reham",   "Ibrahim"),
        ("reemmohamed@gmail.com",   "Reem",    "Mohamed"),
        ("nohaahmed@gmail.com",     "Noha",    "Ahmed"),
        ("maihassan@gmail.com",     "Mai",     "Hassan"),
        ("salmakhalil@gmail.com",   "Salma",   "Khalil"),
        ("ranamohamed@gmail.com",   "Rana",    "Mohamed"),
        ("nesmaibrahim@gmail.com",  "Nesma",   "Ibrahim"),
        ("ghadaahmed@gmail.com",    "Ghada",   "Ahmed"),
        ("daliahassan@gmail.com",   "Dalia",   "Hassan"),
        ("samarmahmoud@gmail.com",  "Samar",   "Mahmoud"),
        ("nihalsalem@gmail.com",    "Nihal",   "Salem"),
        ("asmaayoussef@gmail.com",  "Asmaa",   "Youssef"),
        ("hendibrahim@gmail.com",   "Hend",    "Ibrahim"),
        ("radwaahmed@gmail.com",    "Radwa",   "Ahmed"),
        ("ahmedselim@gmail.com",    "Ahmed",   "Selim"),
        ("mohamedosman@gmail.com",  "Mohamed", "Osman"),
        ("mahmoudhabib@gmail.com",  "Mahmoud", "Habib"),
        ("omartawfik@gmail.com",    "Omar",    "Tawfik"),
        ("khaledwahba@gmail.com",   "Khaled",  "Wahba"),
        ("tarekshaker@gmail.com",   "Tarek",   "Shaker"),
        ("hassandiab@gmail.com",    "Hassan",  "Diab"),
        ("karimqenawy@gmail.com",   "Karim",   "Qenawy"),
        ("youssefzohdy@gmail.com",  "Youssef", "Zohdy"),
        ("ibrahimshalaby@gmail.com","Ibrahim", "Shalaby"),
        ("aliramady@gmail.com",     "Ali",     "Ramady"),
        ("mostafagalal@gmail.com",  "Mostafa", "Galal"),
        ("amrbadr@gmail.com",       "Amr",     "Badr"),
        ("hossamazmy@gmail.com",    "Hossam",  "Azmy"),
        ("walidlotfy@gmail.com",    "Walid",   "Lotfy"),
        ("sherifgouda@gmail.com",   "Sherif",  "Gouda"),
        ("aymansabry@gmail.com",    "Ayman",   "Sabry"),
        ("samehnassar@gmail.com",   "Sameh",   "Nassar"),
        ("waelhalim@gmail.com",     "Wael",    "Halim"),
        ("hazemhafez@gmail.com",    "Hazem",   "Hafez"),
        ("osamafarag@gmail.com",    "Osama",   "Farag"),
        ("tamershehata@gmail.com",  "Tamer",   "Shehata"),
        ("essamatef@gmail.com",     "Essam",   "Atef"),
        ("nassergaber@gmail.com",   "Nasser",  "Gaber"),
        ("ramyshehata@gmail.com",   "Ramy",    "Shehata"),
        ("samymorsi@gmail.com",     "Samy",    "Morsi"),
        ("ashrafismail@gmail.com",  "Ashraf",  "Ismail"),
        ("adelfawzy@gmail.com",     "Adel",    "Fawzy"),
        ("magdygad@gmail.com",      "Magdy",   "Gad"),
        ("hanyamin@gmail.com",      "Hany",    "Amin"),
        ("ramzysalah@gmail.com",    "Ramzy",   "Salah"),
        ("gamalosman@gmail.com",    "Gamal",   "Osman"),
        ("hamdiahmed@gmail.com",    "Hamdi",   "Ahmed"),
        ("hatemmohamed@gmail.com",  "Hatem",   "Mohamed"),
        ("ehabhassan@gmail.com",    "Ehab",    "Hassan"),
        ("samirmahmoud@gmail.com",  "Samir",   "Mahmoud"),
        ("nabilibrahim@gmail.com",  "Nabil",   "Ibrahim"),
        ("bassemsalem@gmail.com",   "Bassem",  "Salem"),
        ("heshamfarouk@gmail.com",  "Hesham",  "Farouk"),
        ("magedyoussef@gmail.com",  "Maged",   "Youssef"),
        ("noursoliman@gmail.com",   "Nour",    "Soliman"),
        ("saraselim@gmail.com",     "Sara",    "Selim"),
        ("fatmaosman@gmail.com",    "Fatma",   "Osman"),
        ("ayatawfik@gmail.com",     "Aya",     "Tawfik"),
        ("mariamwahba@gmail.com",   "Mariam",  "Wahba"),
        ("dinashaker@gmail.com",    "Dina",    "Shaker"),
        ("hanadiab@gmail.com",      "Hana",    "Diab"),
        ("raniaqenawy@gmail.com",   "Rania",   "Qenawy"),
        ("monazohdy@gmail.com",     "Mona",    "Zohdy"),
        ("nadiashalaby@gmail.com",  "Nadia",   "Shalaby"),
        ("emanramady@gmail.com",    "Eman",    "Ramady"),
        ("hebagalal@gmail.com",     "Heba",    "Galal"),
        ("shimaabadr@gmail.com",    "Shimaa",  "Badr"),
        ("doaaazmy@gmail.com",      "Doaa",    "Azmy"),
        ("amiraosman@gmail.com",    "Amira",   "Osman"),
        ("rehamsabry@gmail.com",    "Reham",   "Sabry"),
        ("reemnassar@gmail.com",    "Reem",    "Nassar"),
        ("nohahalim@gmail.com",     "Noha",    "Halim"),
        ("maiibrahim@gmail.com",    "Mai",     "Ibrahim"),
        ("salmaahmed@gmail.com",    "Salma",   "Ahmed"),
        ("ranahassan@gmail.com",    "Rana",    "Hassan"),
        ("nesmamahmoud@gmail.com",  "Nesma",   "Mahmoud"),
        ("ghadasalem@gmail.com",    "Ghada",   "Salem"),
        ("daliafarouk@gmail.com",   "Dalia",   "Farouk"),
        ("samaryoussef@gmail.com",  "Samar",   "Youssef"),
        ("nihalibrahim@gmail.com",  "Nihal",   "Ibrahim"),
        ("asmaahmed@gmail.com",     "Asmaa",   "Ahmed"),
        ("hendmohamed@gmail.com",   "Hend",    "Mohamed"),
        ("radwahassan@gmail.com",   "Radwa",   "Hassan"),
        ("ahmedwahba@gmail.com",    "Ahmed",   "Wahba"),
        ("mohamedselim@gmail.com",  "Mohamed", "Selim"),
        ("mahmoudtawfik@gmail.com", "Mahmoud", "Tawfik"),
        ("omarshaker@gmail.com",    "Omar",    "Shaker"),
        ("khaleddiab@gmail.com",    "Khaled",  "Diab"),
        ("tarekqenawy@gmail.com",   "Tarek",   "Qenawy"),
        ("hassanzohdy@gmail.com",   "Hassan",  "Zohdy"),
        ("karimshalaby@gmail.com",  "Karim",   "Shalaby"),
        ("yousseframady@gmail.com", "Youssef", "Ramady"),
        ("ibrahimgalal@gmail.com",  "Ibrahim", "Galal"),
        ("alibadr@gmail.com",       "Ali",     "Badr"),
        ("mostafaazmy@gmail.com",   "Mostafa", "Azmy"),
        ("amrlotfy@gmail.com",      "Amr",     "Lotfy"),
        ("hossamsabry@gmail.com",   "Hossam",  "Sabry"),
        ("walidnassar@gmail.com",   "Walid",   "Nassar"),
        ("sherifhalim@gmail.com",   "Sherif",  "Halim"),
        ("aymanhafez@gmail.com",    "Ayman",   "Hafez"),
        ("samehfarag@gmail.com",    "Sameh",   "Farag"),
        ("waeladly@gmail.com",      "Wael",    "Adly"),
        ("hazematef@gmail.com",     "Hazem",   "Atef"),
        ("osamagaber@gmail.com",    "Osama",   "Gaber"),
        ("tamerhalim@gmail.com",    "Tamer",   "Halim"),
        ("essammorsi@gmail.com",    "Essam",   "Morsi"),
        ("nasserismail@gmail.com",  "Nasser",  "Ismail"),
        ("ramyfawzy@gmail.com",     "Ramy",    "Fawzy"),
        ("samygad@gmail.com",       "Samy",    "Gad"),
        ("ashrafamin@gmail.com",    "Ashraf",  "Amin"),
        ("adelsalah@gmail.com",     "Adel",    "Salah"),
        ("magdyosman@gmail.com",    "Magdy",   "Osman"),
        ("hanyhabib@gmail.com",     "Hany",    "Habib"),
        ("ramzyselim@gmail.com",    "Ramzy",   "Selim"),
        ("gamaltawfik@gmail.com",   "Gamal",   "Tawfik"),
        ("hamdimohamed@gmail.com",  "Hamdi",   "Mohamed"),
        ("hatemhassan@gmail.com",   "Hatem",   "Hassan"),
        ("ehabibrahim@gmail.com",   "Ehab",    "Ibrahim"),
        ("samiryoussef@gmail.com",  "Samir",   "Youssef"),
        ("nabilmahmoud@gmail.com",  "Nabil",   "Mahmoud"),
        ("bassemahmed@gmail.com",   "Bassem",  "Ahmed"),
        ("heshamsalem@gmail.com",   "Hesham",  "Salem"),
        ("magedfarouk@gmail.com",   "Maged",   "Farouk"),
        ("nourwahba@gmail.com",     "Nour",    "Wahba"),
        ("saraibrahim@gmail.com",   "Sara",    "Ibrahim"),
        ("fatmasalem@gmail.com",    "Fatma",   "Salem"),
        ("ayayoussef@gmail.com",    "Aya",     "Youssef"),
        ("mariammohamed@gmail.com", "Mariam",  "Mohamed"),
        ("dinasalem@gmail.com",     "Dina",    "Salem"),
        ("hanamahmoud@gmail.com",   "Hana",    "Mahmoud"),
        ("raniamohamed@gmail.com",  "Rania",   "Mohamed"),
        ("monahassan@gmail.com",    "Mona",    "Hassan"),
        ("nadiaahmed@gmail.com",    "Nadia",   "Ahmed"),
        ("emanmohamed@gmail.com",   "Eman",    "Mohamed"),
        ("hebaibrahim@gmail.com",   "Heba",    "Ibrahim"),
        ("shimaaahmed@gmail.com",   "Shimaa",  "Ahmed"),
        ("doaamohamed@gmail.com",   "Doaa",    "Mohamed"),
        ("amiraahmed@gmail.com",    "Amira",   "Ahmed"),
        ("rehammohamed@gmail.com",  "Reham",   "Mohamed"),
        ("reemhassan@gmail.com",    "Reem",    "Hassan"),
        ("nohamohamed@gmail.com",   "Noha",    "Mohamed"),
        ("maiahmed@gmail.com",      "Mai",     "Ahmed"),
        ("salmamohamed@gmail.com",  "Salma",   "Mohamed"),
        ("ranaibrahim@gmail.com",   "Rana",    "Ibrahim"),
        ("nesmahassan@gmail.com",   "Nesma",   "Hassan"),
    ];

    private static async Task SeedDoctorsAsync(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext db,
        ILogger logger)
    {
        foreach (var (specialtyId, doctors) in GetDoctorsBySpecialty())
        {
            int existingCount = await db.DoctorProfiles.CountAsync(dp => dp.SpecialtyId == specialtyId);
            int toCreate = Math.Max(0, 5 - existingCount);

            if (toCreate == 0)
                continue;

            int created = 0;

            foreach (var (email, firstName, lastName, fee, experience) in doctors)
            {
                if (created >= toCreate) break;

                var existing = await userManager.FindByEmailAsync(email);
                if (existing is not null)
                {
                    bool profileExists = await db.DoctorProfiles.AnyAsync(dp => dp.UserId == existing.Id);
                    if (profileExists)
                    {
                        created++;
                        continue;
                    }
                }

                ApplicationUser user;
                if (existing is not null)
                {
                    user = existing;
                }
                else
                {
                    user = new ApplicationUser
                    {
                        Id = Guid.NewGuid(),
                        UserName = email,
                        Email = email,
                        FirstName = firstName,
                        LastName = lastName,
                        Role = UserRole.Doctor,
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                    };

                    var result = await userManager.CreateAsync(user, Password);
                    if (!result.Succeeded)
                    {
                        var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                        logger.LogWarning("Failed to create doctor {Email}: {Errors}", email, errors);
                        continue;
                    }
                }

                var profileId = Guid.NewGuid();
                var latOffset = (created * 0.001) - 0.002;
                var lonOffset = (created * 0.001) - 0.002;

                db.DoctorProfiles.Add(new DoctorProfile
                {
                    Id = profileId,
                    UserId = user.Id,
                    SpecialtyId = specialtyId,
                    ClinicName = $"Dr. {firstName} {lastName} Clinic",
                    ClinicAddress = SadatAddress,
                    Latitude = SadatLat + latOffset,
                    Longitude = SadatLon + lonOffset,
                    ConsultationFee = fee,
                    ExperienceYears = experience,
                    Bio = $"Specialist with {experience} years of clinical experience in Sadat City.",
                    Status = DoctorStatus.Approved,
                    ReviewedAt = DateTime.UtcNow.AddDays(-30),
                    CreatedAt = DateTime.UtcNow,
                });

                foreach (var day in new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday })
                {
                    db.DoctorAvailabilities.Add(new DoctorAvailability
                    {
                        Id = Guid.NewGuid(),
                        DoctorProfileId = profileId,
                        DayOfWeek = day,
                        StartTime = new TimeSpan(9, 0, 0),
                        EndTime = new TimeSpan(17, 0, 0),
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow,
                    });
                }

                created++;
            }

            await db.SaveChangesAsync();
            logger.LogInformation("Seeded {Count} doctor(s) for specialty {SpecialtyId}", created, specialtyId);
        }
    }

    private static async Task SeedAppointmentsAsync(
        ApplicationDbContext db,
        Guid patient1Id,
        Guid patient2Id,
        ILogger logger)
    {
        if (patient1Id == Guid.Empty || patient2Id == Guid.Empty)
        {
            logger.LogWarning("Skipping appointment seeding — patient IDs are invalid.");
            return;
        }

        var allProfileIds = await db.DoctorProfiles.Select(dp => dp.Id).ToListAsync();
        var patients = new[] { patient1Id, patient2Id };
        var now = DateTime.UtcNow;
        int count = 0;

        for (int i = 0; i < allProfileIds.Count; i++)
        {
            var profileId = allProfileIds[i];

            bool exists = await db.Appointments.AnyAsync(a =>
                a.DoctorProfileId == profileId &&
                (a.PatientId == patient1Id || a.PatientId == patient2Id));

            if (exists) continue;

            var patientId = patients[i % 2];

            var (status, paymentStatus, scheduledAt) = (i % 3) switch
            {
                0 => (AppointmentStatus.Completed, PaymentStatus.Paid, now.AddDays(-30).AddHours(i)),
                1 => (AppointmentStatus.Confirmed, PaymentStatus.Pending, now.AddDays(7).AddHours(i)),
                _ => (AppointmentStatus.Scheduled, PaymentStatus.Unpaid, now.AddDays(14).AddHours(i)),
            };

            db.Appointments.Add(new Appointment
            {
                Id = Guid.NewGuid(),
                PatientId = patientId,
                DoctorProfileId = profileId,
                ScheduledAt = scheduledAt,
                LocationName = SadatAddress,
                Status = status,
                PaymentStatus = paymentStatus,
                CreatedAt = DateTime.UtcNow,
            });

            count++;
        }

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} appointment(s).", count);
    }

    private static IEnumerable<(Guid SpecialtyId, (string Email, string FirstName, string LastName, decimal Fee, int Experience)[] Doctors)> GetDoctorsBySpecialty()
    {
        return
        [
            // Cardiology — 1 existing, need 4
            (new Guid("ECDBFFF5-A41D-4307-A242-3E94DF8162E5"),
            [
                ("ahmedhassan@gmail.com",  "Ahmed",   "Hassan",   500m, 12),
                ("mahmoudsalem@gmail.com", "Mahmoud", "Salem",    500m,  8),
                ("omaribrahim@gmail.com",  "Omar",    "Ibrahim",  500m, 15),
                ("khaledyoussef@gmail.com","Khaled",  "Youssef",  500m, 10),
                ("tarekgamal@gmail.com",   "Tarek",   "Gamal",    500m,  7),
            ]),

            // Dentistry — 1 existing, need 4
            (new Guid("1B07FCE3-AC1C-4FE8-B0E9-A0FD3DBDC0A4"),
            [
                ("saramahmoud@gmail.com",  "Sara",   "Mahmoud",  350m, 6),
                ("nourahmed@gmail.com",    "Nour",   "Ahmed",    350m, 4),
                ("raniahassan@gmail.com",  "Rania",  "Hassan",   350m, 8),
                ("monakhalil@gmail.com",   "Mona",   "Khalil",   350m, 5),
                ("dinahussein@gmail.com",  "Dina",   "Hussein",  350m, 9),
            ]),

            // Dermatology — 0 existing, need 5
            (new Guid("65250CF7-B517-4D2B-9C68-C1EEA196CAFA"),
            [
                ("yasminnasser@gmail.com", "Yasmin", "Nasser",   400m,  7),
                ("dinakamel@gmail.com",    "Dina",   "Kamel",    400m,  5),
                ("hebarashid@gmail.com",   "Heba",   "Rashid",   400m, 11),
                ("shimaamansour@gmail.com","Shimaa", "Mansour",  400m,  6),
                ("reemaziz@gmail.com",     "Reem",   "Aziz",     400m,  8),
            ]),

            // Emergency Medicine — 1 existing, need 4
            (new Guid("59059F56-D68D-4B57-AAEC-A7BAFD6A71C0"),
            [
                ("tarekfarouk@gmail.com",  "Tarek",  "Farouk",   450m, 10),
                ("waelabdallah@gmail.com", "Wael",   "Abdallah", 450m,  8),
                ("hossamrizk@gmail.com",   "Hossam", "Rizk",     450m, 12),
                ("karimsaber@gmail.com",   "Karim",  "Saber",    450m,  6),
                ("samehragab@gmail.com",   "Sameh",  "Ragab",    450m, 14),
            ]),

            // ENT — 0 existing, need 5
            (new Guid("6083B2BB-BDB1-4409-AA91-B0AE5646F99D"),
            [
                ("ibrahimragab@gmail.com", "Ibrahim","Ragab",    400m,  9),
                ("amrghali@gmail.com",     "Amr",    "Ghali",    400m,  7),
                ("samehbarakat@gmail.com", "Sameh",  "Barakat",  400m, 11),
                ("ramyzaki@gmail.com",     "Ramy",   "Zaki",     400m,  5),
                ("ashrafbadawi@gmail.com", "Ashraf", "Badawi",   400m, 13),
            ]),

            // Family Medicine — 0 existing, need 5
            (new Guid("82E19C0E-59D3-4303-A26F-4714C363D7A2"),
            [
                ("walidtalat@gmail.com",   "Walid",  "Talat",    250m,  8),
                ("aymanhegazy@gmail.com",  "Ayman",  "Hegazy",   250m, 10),
                ("sherifhelal@gmail.com",  "Sherif", "Helal",    250m,  6),
                ("hazemsalah@gmail.com",   "Hazem",  "Salah",    250m, 12),
                ("osamaamin@gmail.com",    "Osama",  "Amin",     250m,  9),
            ]),

            // Gastroenterology — 0 existing, need 5
            (new Guid("3079E6F0-AF0A-4B9F-ABED-B8D6ACAA05AC"),
            [
                ("tamerkamel@gmail.com",   "Tamer",  "Kamel",    450m,  8),
                ("essamrashid@gmail.com",  "Essam",  "Rashid",   450m, 11),
                ("nassergad@gmail.com",    "Nasser", "Gad",      450m,  7),
                ("magdyfawzy@gmail.com",   "Magdy",  "Fawzy",    450m, 14),
                ("samyismail@gmail.com",   "Samy",   "Ismail",   450m,  6),
            ]),

            // General Surgery — 0 existing, need 5
            (new Guid("8A7E8D84-6429-4D3C-9788-F49E66A55A03"),
            [
                ("hanysalah@gmail.com",    "Hany",   "Salah",    600m, 15),
                ("gamalaziz@gmail.com",    "Gamal",  "Aziz",     600m, 12),
                ("adelfouad@gmail.com",    "Adel",   "Fouad",    600m, 18),
                ("hassansharaf@gmail.com", "Hassan", "Sharaf",   600m, 10),
                ("ramzymohamed@gmail.com", "Ramzy",  "Mohamed",  600m,  8),
            ]),

            // Hematology — 0 existing, need 5
            (new Guid("9257DEBA-F767-4D61-B513-AB38F5A4D5F7"),
            [
                ("mariamsaad@gmail.com",   "Mariam", "Saad",     500m,  9),
                ("ayahamdy@gmail.com",     "Aya",    "Hamdy",    500m,  6),
                ("fatmagalal@gmail.com",   "Fatma",  "Galal",    500m, 12),
                ("doaabadr@gmail.com",     "Doaa",   "Badr",     500m,  7),
                ("amiralotfy@gmail.com",   "Amira",  "Lotfy",    500m, 10),
            ]),

            // Infectious Diseases — 0 existing, need 5
            (new Guid("CEB9C582-001B-4A2D-ABF1-1B82E0C1D75A"),
            [
                ("mostafashehata@gmail.com","Mostafa","Shehata", 400m,  8),
                ("alaagaber@gmail.com",     "Alaa",  "Gaber",    400m,  6),
                ("bassematef@gmail.com",    "Bassem","Atef",     400m, 11),
                ("heshamadly@gmail.com",    "Hesham","Adly",     400m,  9),
                ("nabilfarag@gmail.com",    "Nabil", "Farag",    400m, 14),
            ]),

            // Internal Medicine — 0 existing, need 5
            (new Guid("7B6CB382-E7B4-44B9-B03C-6E46D06C32E7"),
            [
                ("osamahafez@gmail.com",   "Osama",  "Hafez",    350m, 10),
                ("tarekhalim@gmail.com",   "Tarek",  "Halim",    350m,  8),
                ("waelnassar@gmail.com",   "Wael",   "Nassar",   350m, 12),
                ("mohamedsabry@gmail.com", "Mohamed","Sabry",    350m,  7),
                ("ahmedgouda@gmail.com",   "Ahmed",  "Gouda",    350m, 15),
            ]),

            // Nephrology — 0 existing, need 5
            (new Guid("016CC7AC-2F73-4AC2-81F2-0C28E4540ECF"),
            [
                ("khaledramzy@gmail.com",  "Khaled", "Ramzy",    500m, 11),
                ("youssefsalem@gmail.com", "Youssef","Salem",    500m,  8),
                ("ibrahimnour@gmail.com",  "Ibrahim","Nour",     500m, 13),
                ("sherifkamal@gmail.com",  "Sherif", "Kamal",    500m,  9),
                ("nohamansour@gmail.com",  "Noha",   "Mansour",  500m,  6),
            ]),

            // Oncology — 0 existing, need 5
            (new Guid("A50BD034-9E47-4DFE-BF8E-5BF78004231D"),
            [
                ("mairashid@gmail.com",    "Mai",    "Rashid",   600m, 12),
                ("rehamhassan@gmail.com",  "Reham",  "Hassan",   600m,  9),
                ("nadiaibrahim@gmail.com", "Nadia",  "Ibrahim",  600m, 14),
                ("emankhalil@gmail.com",   "Eman",   "Khalil",   600m,  8),
                ("hanayoussef@gmail.com",  "Hana",   "Youssef",  600m, 11),
            ]),

            // Ophthalmology — 3 existing, need 2
            (new Guid("7A820D80-8048-4E5B-BB6B-A49301FD2E68"),
            [
                ("karimfarouk@gmail.com",  "Karim",  "Farouk",   400m,  8),
                ("samehaziz@gmail.com",    "Sameh",  "Aziz",     400m,  6),
                ("khaledaziz@gmail.com",   "Khaled", "Aziz",     400m, 10),
                ("omarnabil@gmail.com",    "Omar",   "Nabil",    400m,  7),
                ("tarekamer@gmail.com",    "Tarek",  "Amer",     400m,  9),
            ]),

            // Orthopedics — 1 existing, need 4
            (new Guid("ECDCBD4C-B7EA-41A5-A5CF-F0AD89F015CD"),
            [
                ("waelhegazy@gmail.com",   "Wael",   "Hegazy",   550m, 12),
                ("hazembarakat@gmail.com", "Hazem",  "Barakat",  550m,  8),
                ("ramysalah@gmail.com",    "Ramy",   "Salah",    550m, 10),
                ("tamerbadawi@gmail.com",  "Tamer",  "Badawi",   550m, 14),
                ("amrkamal@gmail.com",     "Amr",    "Kamal",    550m,  7),
            ]),

            // Pain Management — 0 existing, need 5
            (new Guid("9B09362A-AFAA-4086-951B-3656557DF294"),
            [
                ("amrhassan@gmail.com",    "Amr",    "Hassan",   450m,  9),
                ("alimohamed@gmail.com",   "Ali",    "Mohamed",  450m,  7),
                ("hossamfouad@gmail.com",  "Hossam", "Fouad",    450m, 11),
                ("hassannasser@gmail.com", "Hassan", "Nasser",   450m,  8),
                ("mahmoudragab@gmail.com", "Mahmoud","Ragab",    450m, 13),
            ]),

            // Pediatrics — 0 existing, need 5
            (new Guid("D5DAF61E-BC5E-467A-9E2E-DCF5924D900D"),
            [
                ("sarakhalil@gmail.com",   "Sara",   "Khalil",   350m,  8),
                ("noursalem@gmail.com",    "Nour",   "Salem",    350m,  6),
                ("raniaahmed@gmail.com",   "Rania",  "Ahmed",    350m, 10),
                ("monaibrahim@gmail.com",  "Mona",   "Ibrahim",  350m,  7),
                ("yasminhassan@gmail.com", "Yasmin", "Hassan",   350m,  9),
            ]),

            // Physical Therapy — 0 existing, need 5
            (new Guid("4F466134-A956-4582-8B6C-3571123EA0C7"),
            [
                ("dinasaber@gmail.com",    "Dina",   "Saber",    300m, 6),
                ("hebatalat@gmail.com",    "Heba",   "Talat",    300m, 8),
                ("shimaahelal@gmail.com",  "Shimaa", "Helal",    300m, 5),
                ("reemsalah@gmail.com",    "Reem",   "Salah",    300m, 9),
                ("amirahassan@gmail.com",  "Amira",  "Hassan",   300m, 7),
            ]),

            // Psychiatry — 0 existing, need 5
            (new Guid("1D2DCA0A-BE2D-43F3-AB54-A43FBB0FD168"),
            [
                ("walidfarouk@gmail.com",  "Walid",  "Farouk",   450m, 12),
                ("aymanibrahim@gmail.com", "Ayman",  "Ibrahim",  450m,  9),
                ("adelmahmoud@gmail.com",  "Adel",   "Mahmoud",  450m, 14),
                ("magdyhassan@gmail.com",  "Magdy",  "Hassan",   450m,  8),
                ("gamalsalem@gmail.com",   "Gamal",  "Salem",    450m, 11),
            ]),

            // Pulmonology — 0 existing, need 5
            (new Guid("BA25A0C7-6657-45AD-9373-CA70E4A3B3FD"),
            [
                ("essamkhalil@gmail.com",  "Essam",  "Khalil",   450m, 10),
                ("nassersaber@gmail.com",  "Nasser", "Saber",    450m,  8),
                ("samyragab@gmail.com",    "Samy",   "Ragab",    450m, 12),
                ("ramzyaziz@gmail.com",    "Ramzy",  "Aziz",     450m,  7),
                ("hanyibrahim@gmail.com",  "Hany",   "Ibrahim",  450m, 15),
            ]),

            // Radiology — 0 existing, need 5
            (new Guid("026F0B5D-225C-4A3A-A2F2-72EA634DBD3F"),
            [
                ("ibrahimfouad@gmail.com", "Ibrahim","Fouad",    500m, 11),
                ("samehhelal@gmail.com",   "Sameh",  "Helal",    500m,  9),
                ("tarekkhalil@gmail.com",  "Tarek",  "Khalil",   500m, 13),
                ("waelkamel@gmail.com",    "Wael",   "Kamel",    500m,  8),
                ("khaledbadawi@gmail.com", "Khaled", "Badawi",   500m, 10),
            ]),

            // Urology — 0 existing, need 5
            (new Guid("E7B22771-06AD-4044-9DC5-9A658E746FFC"),
            [
                ("omarmansour@gmail.com",  "Omar",   "Mansour",  500m, 10),
                ("karimnasser@gmail.com",  "Karim",  "Nasser",   500m,  8),
                ("yousseffouad@gmail.com", "Youssef","Fouad",    500m, 12),
                ("alisaber@gmail.com",     "Ali",    "Saber",    500m,  9),
                ("hassanmahmoud@gmail.com","Hassan", "Mahmoud",  500m,  7),
            ]),
        ];
    }
}
