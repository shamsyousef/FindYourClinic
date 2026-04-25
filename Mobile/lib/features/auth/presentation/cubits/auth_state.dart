import '../../domain/entities/auth_entities.dart';

/// Auth states using sealed classes (Dart 3+, no Freezed).
sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final AuthResult result;
  AuthSuccess(this.result);
}

class AuthRegistered extends AuthState {
  final RegisterResult result;
  AuthRegistered(this.result);
}

class AuthGoogleResult extends AuthState {
  final GoogleAuthResult result;
  AuthGoogleResult(this.result);
}

class AuthPasswordResetSent extends AuthState {}

class AuthPasswordResetSuccess extends AuthState {}

class AuthLoggedOut extends AuthState {}

class AuthDoctorStatusLoaded extends AuthState {
  final DoctorStatusResult result;
  AuthDoctorStatusLoaded(this.result);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
