class UserProfileEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? profileImageUrl;

  const UserProfileEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName';
}
