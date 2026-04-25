import '../../../../core/network/api_result.dart';
import '../entities/auth_entities.dart';

/// Auth repository contract — domain layer.
abstract class AuthRepository {
  Future<ApiResult<AuthResult>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<RegisterResult>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? specialtyId,
  });

  Future<ApiResult<GoogleAuthResult>> googleLogin({
    required String idToken,
    String? role,
  });

  Future<ApiResult<void>> forgotPassword({required String email});

  Future<ApiResult<void>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<ApiResult<AuthResult>> refreshToken({required String refreshToken});

  Future<ApiResult<DoctorStatusResult>> getDoctorStatus();

  Future<void> logout();
}
