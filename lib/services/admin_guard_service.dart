import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Access Guard
/// Checks if the current user has admin access via the `admin_access` table.
/// Used to protect the /admin route.
class AdminGuardService {
  static final _supabase = Supabase.instance.client;

  /// Check if current user is an admin
  static Future<bool> isAdmin() async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) return false;

      final response = await _supabase
          .from('admin_access')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) print('⚠️ Admin check failed: $e');
      return false; // Fail closed
    }
  }
}
