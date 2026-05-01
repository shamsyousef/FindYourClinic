import '../../../../core/network/api_result.dart';
import '../entities/auth_entities.dart';
import '../repos/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<ApiResult<AuthResult>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}

class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<ApiResult<RegisterResult>> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? specialtyId,
  }) => _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        specialtyId: specialtyId,
      );
}

class GoogleLoginUseCase {
  final AuthRepository _repository;
  const GoogleLoginUseCase(this._repository);

  Future<ApiResult<GoogleAuthResult>> call({
    required String idToken,
    String? role,
  }) => _repository.googleLogin(idToken: idToken, role: role);
}

class ForgotPasswordUseCase {
  final AuthRepository _repository;
  const ForgotPasswordUseCase(this._repository);

  Future<ApiResult<void>> call({required String email}) =>
      _repository.forgotPassword(email: email);
}

class ResetPasswordUseCase {
  final AuthRepository _repository;
  const ResetPasswordUseCase(this._repository);

  Future<ApiResult<void>> call({
    required String token,
    required String newPassword,
  }) => _repository.resetPassword(token: token, newPassword: newPassword);
}

class ChangePasswordUseCase {
  final AuthRepository _repository;
  const ChangePasswordUseCase(this._repository);

  Future<ApiResult<void>> call({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}

class LogoutUseCase {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}

class GetDoctorStatusUseCase {
  final AuthRepository _repository;
  const GetDoctorStatusUseCase(this._repository);

  Future<ApiResult<DoctorStatusResult>> call() => _repository.getDoctorStatus();
}
