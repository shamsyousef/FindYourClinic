import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_cubit.dart';
import 'core/di/service_locator.dart';

class FindYourClinicApp extends StatefulWidget {
  const FindYourClinicApp({super.key});

  @override
  State<FindYourClinicApp> createState() => _FindYourClinicAppState();
}

class _FindYourClinicAppState extends State<FindYourClinicApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeModeCubit>(
      create: (_) => sl<ThemeModeCubit>()..load(),
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Find Your Clinic',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
