import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_state.dart';

/// AuthCubit — depends ONLY on use cases, never on repositories directly.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetDoctorStatusUseCase _getDoctorStatusUseCase;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GoogleLoginUseCase googleLoginUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required LogoutUseCase logoutUseCase,
    required GetDoctorStatusUseCase getDoctorStatusUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _googleLoginUseCase = googleLoginUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _logoutUseCase = logoutUseCase,
        _getDoctorStatusUseCase = getDoctorStatusUseCase,
        super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await _loginUseCase(email: email, password: password);
    switch (result) {
      case Success(:final data):
        emit(AuthSuccess(data));
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? specialtyId,
  }) async {
    emit(AuthLoading());
    final result = await _registerUseCase(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
      specialtyId: specialtyId,
    );
    switch (result) {
      case Success(:final data):
        emit(AuthRegistered(data));
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }

  Future<void> googleLogin({required String idToken, String? role}) async {
    emit(AuthLoading());
    final result = await _googleLoginUseCase(idToken: idToken, role: role);
    switch (result) {
      case Success(:final data):
        emit(AuthGoogleResult(data));
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(AuthLoading());
    final result = await _forgotPasswordUseCase(email: email);
    switch (result) {
      case Success():
        emit(AuthPasswordResetSent());
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    emit(AuthLoading());
    final result =
        await _resetPasswordUseCase(token: token, newPassword: newPassword);
    switch (result) {
      case Success():
        emit(AuthPasswordResetSuccess());
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }

  Future<void> getDoctorStatus() async {
    emit(AuthLoading());
    final result = await _getDoctorStatusUseCase();
    switch (result) {
      case Success(:final data):
        emit(AuthDoctorStatusLoaded(data));
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    emit(AuthLoggedOut());
  }
}
