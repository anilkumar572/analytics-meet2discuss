import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../auth/login_page.dart';
import '../dashboard/dashboard_page.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: _GoRouterRefreshStream(authCubit.stream),
      redirect: (ctx, state) {
        final authState = authCubit.state;
        final onLogin = state.matchedLocation == '/login';

        if (authState is Authenticated) {
          return onLogin ? '/dashboard' : null;
        }
        if (authState is AccessDenied) {
          return '/login';
        }
        if (authState is Unauthenticated || authState is AuthInitial) {
          return onLogin ? null : '/login';
        }
        // AuthLoading — stay on current page
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardPage(),
        ),
      ],
    );
  }
}
