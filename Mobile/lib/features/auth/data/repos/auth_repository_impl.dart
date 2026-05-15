import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/utils/token_storage.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repos/auth_repository.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  const AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  @override
  Future<ApiResult<AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Login failed'));
      }
      final result = AuthResponseModel.fromJson(
        body['data'] as Map<String, dynamic>,
      ).toEntity();
      await _persistAuth(result);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<RegisterResult>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? specialtyId,
  }) async {
    try {
      final data = <String, dynamic>{
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };
      if (role.toLowerCase() == 'doctor') {
        data['fullName'] = '$firstName $lastName'.trim();
      }
      if (specialtyId != null) data['specialtyId'] = specialtyId;

      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Registration failed'));
      }
      final result = RegisterResultModel.fromJson(
        body['data'] as Map<String, dynamic>,
      ).toEntity();

      // If patient registration returns tokens directly, persist them.
      if (result.authResult != null) {
        await _persistAuth(result.authResult!);
      }
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<GoogleAuthResult>> googleLogin({
    required String idToken,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{'idToken': idToken};
      if (role != null) data['role'] = role;

      final response = await _apiClient.dio.post(
        ApiEndpoints.googleLogin,
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Google login failed'));
      }
      final result = GoogleAuthResultModel.fromJson(
        body['data'] as Map<String, dynamic>,
      ).toEntity();

      if (result.authResult != null) {
        await _persistAuth(result.authResult!);
      }
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> forgotPassword({required String email}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Failed to send reset link'));
      }
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Failed to change password'));
      }
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'newPassword': newPassword},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Password reset failed'));
      }
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<AuthResult>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Token refresh failed'));
      }
      final result = AuthResponseModel.fromJson(
        body['data'] as Map<String, dynamic>,
      ).toEntity();
      await _persistAuth(result);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<DoctorStatusResult>> getDoctorStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.doctorMyStatus);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Failed to get status'));
      }
      final data = body['data'] as Map<String, dynamic>;
      return Success(DoctorStatusResult(
        status: data['status'] as String? ?? 'PendingReview',
        rejectionReason: data['rejectionReason'] as String?,
        submittedAt: data['submittedAt'] != null
            ? DateTime.tryParse(data['submittedAt'] as String)
            : null,
        documentCount: (data['documentCount'] as num?)?.toInt() ?? 0,
      ));
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> requestAccountDeletion({required String password}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.requestAccountDeletion,
        data: {'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Failed to request account deletion'));
      }
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Persist tokens and user info after successful auth.
  Future<void> _persistAuth(AuthResult result) async {
    await _tokenStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    await _tokenStorage.saveUserRole(result.user.role);
    await _tokenStorage.saveUserId(result.user.id);
  }
}
