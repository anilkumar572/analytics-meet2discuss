import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'auth_state.dart';
import 'auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  StreamSubscription<sb.User?>? _authSubscription;

  AuthCubit(this._authService) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.onAuthStateChange.listen(
      (sb.User? user) async {
        if (user == null) {
          emit(Unauthenticated());
        } else {
          await _verifyAdmin(user);
        }
      },
      onError: (Object error) {
        emit(AuthFailure(error.toString()));
      },
    );
  }

  Future<void> _verifyAdmin(sb.User user) async {
    emit(AuthLoading());
    try {
      final role = await _authService.getAdminUserRole(user.id);
      if (role != null) {
        emit(Authenticated(user: user, role: role));
      } else {
        emit(AccessDenied(user: user, email: user.email ?? ''));
      }
    } catch (e) {
      emit(AuthFailure('Verification failed: $e'));
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        await _verifyAdmin(user);
      } else {
        emit(AuthFailure('Invalid credentials. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
