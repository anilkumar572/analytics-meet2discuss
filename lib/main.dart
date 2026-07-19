import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/supabase_config.dart';
import 'core/routes.dart';
import 'auth/auth_service.dart';
import 'auth/auth_cubit.dart';
import 'dashboard/analytics_service.dart';
import 'dashboard/dashboard_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Supabase failed to initialize: $e');
    print('Running in Demo Mode. Update lib/core/constants.dart to connect.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final analyticsService = AnalyticsService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(authService)),
        BlocProvider<DashboardCubit>(
          create: (_) => DashboardCubit(analyticsService),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Meet2Discuss Admin Dashboard',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surface,
                error: AppColors.danger,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              cardTheme: CardThemeData(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: AppColors.border,
                thickness: 1,
              ),
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: MaterialStateProperty.all(
                    AppColors.textMuted.withOpacity(0.4)),
                radius: const Radius.circular(8),
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: AppColors.surfaceElevated,
                contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            routerConfig: AppRouter.router(context),
          );
        },
      ),
    );
  }
}
