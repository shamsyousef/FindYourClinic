import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../utils/token_storage.dart';
import '../../features/auth/data/repos/auth_repository_impl.dart';
import '../../features/auth/domain/repos/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/doctor_onboarding/data/repos/onboarding_repository_impl.dart';
import '../../features/doctor_onboarding/domain/repos/onboarding_repository.dart';
import '../../features/doctor_onboarding/domain/usecases/upload_documents_usecase.dart';
import '../../features/doctor_onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../features/auth/data/repos/specialty_repository_impl.dart';
import '../../features/auth/domain/repos/specialty_repository.dart';
import '../../features/auth/domain/usecases/get_specialties_usecase.dart';
import '../../features/auth/presentation/cubits/specialty_cubit.dart';

final sl = GetIt.instance;

/// Initialize all dependencies. Called once at app startup.
Future<void> initServiceLocator() async {
  // ─── Core ───
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl<TokenStorage>()),
  );

  // ─── Auth Feature ───
  _initAuth();

  // ─── Specialty Feature ───
  _initSpecialties();

  // ─── Doctor Onboarding Feature ───
  _initOnboarding();
}

void _initAuth() {
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl<ApiClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // Use Cases
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GoogleLoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => ForgotPasswordUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => ResetPasswordUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetDoctorStatusUseCase(sl<AuthRepository>()));

  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      googleLoginUseCase: sl<GoogleLoginUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getDoctorStatusUseCase: sl<GetDoctorStatusUseCase>(),
    ),
  );
}

void _initSpecialties() {
  sl.registerLazySingleton<SpecialtyRepository>(
    () => SpecialtyRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => GetSpecialtiesUseCase(sl<SpecialtyRepository>()));
  sl.registerFactory(() => SpecialtyCubit(sl<GetSpecialtiesUseCase>()));
}

void _initOnboarding() {
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => UploadDocumentsUseCase(sl<OnboardingRepository>()));
  sl.registerFactory(
    () => OnboardingCubit(uploadDocumentsUseCase: sl<UploadDocumentsUseCase>()),
  );
}
