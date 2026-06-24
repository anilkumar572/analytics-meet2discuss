import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// Custom auth states for Cubit — namespaced to avoid clash with supabase AuthState
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final sb.User user;
  final String role;
  Authenticated({required this.user, required this.role});
}

class AccessDenied extends AuthState {
  final sb.User user;
  final String email;
  AccessDenied({required this.user, required this.email});
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String errorMessage;
  AuthFailure(this.errorMessage);
}
