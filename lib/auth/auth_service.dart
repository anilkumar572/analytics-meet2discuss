import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/supabase_config.dart';

class AuthService {
  sb.SupabaseClient get _client => SupabaseConfig.client;

  Future<sb.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: Uri.base.origin,
    );
  }

  Future<String?> getAdminUserRole(String userId) async {
    try {
      final data = await _client
          .from('admin_users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      print('Admin Data: $data');

      if (data == null) return null;

      if (data['is_active'] != true) return null;

      return data['role_id'].toString();
    } catch (e) {
      print('Error verifying admin permissions: $e');
      return null;
    }
  }

  sb.User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Map the raw Supabase auth stream to User? to avoid type conflicts
  Stream<sb.User?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
