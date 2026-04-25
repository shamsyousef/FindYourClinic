namespace FindYourClinic.Domain.Constants;

public static class NotificationTypes
{
    public const string DoctorApproved = "doctor_approved";
    public const string DoctorRejected = "doctor_rejected";
    public const string AppointmentBooked = "appointment_booked";
    public const string AppointmentConfirmed = "appointment_confirmed";
    public const string AppointmentCancelled = "appointment_cancelled";
    public const string AppointmentReminder = "appointment_reminder";
    public const string AppointmentCompleted = "appointment_completed";
    public const string NewMessage = "new_message";
    public const string NewReview = "new_review";
}
