/// User entity — domain layer, no Flutter imports.
class User {
  final String id;
  final String email;
  final String fullName;
  final String firstName;
  final String lastName;
  final String role;
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.firstName = '',
    this.lastName = '',
    required this.role,
    this.profileImageUrl,
  });

  bool get isDoctor => role == 'Doctor';
  bool get isPatient => role == 'Patient';
  bool get isAdmin => role == 'Admin';
}

/// Auth tokens returned after login/register.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}

/// Combined auth result — tokens + user.
class AuthResult {
  final AuthTokens tokens;
  final User user;

  const AuthResult({required this.tokens, required this.user});
}

/// Google login may need extra registration step.
class GoogleAuthResult {
  final AuthResult? authResult;
  final String? pendingToken;
  final bool requiresRegistration;

  const GoogleAuthResult({
    this.authResult,
    this.pendingToken,
    this.requiresRegistration = false,
  });
}

/// Doctor registration result — may need document upload.
class RegisterResult {
  final AuthResult? authResult;
  final String? pendingToken;
  final bool requiresDocumentUpload;

  const RegisterResult({
    this.authResult,
    this.pendingToken,
    this.requiresDocumentUpload = false,
  });
}

/// Doctor approval status returned by GET /api/doctors/me/status.
class DoctorStatusResult {
  final String status; // 'PendingReview' | 'Approved' | 'Rejected'
  final String? rejectionReason;
  final DateTime? submittedAt;
  final int documentCount;

  const DoctorStatusResult({
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.documentCount = 0,
  });

  bool get isPending => status == 'PendingReview';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
}
