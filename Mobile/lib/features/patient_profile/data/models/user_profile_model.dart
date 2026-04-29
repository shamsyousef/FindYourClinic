import '../../domain/entities/user_profile_entity.dart';

class UserProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? profileImageUrl;

  const UserProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  UserProfileEntity toEntity() => UserProfileEntity(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        profileImageUrl: profileImageUrl,
      );
}
