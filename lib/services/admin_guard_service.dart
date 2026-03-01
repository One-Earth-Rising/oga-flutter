import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Access Guard
/// Checks if the current user has admin access via the `admin_access` table.
/// Used to protect the /admin route.
class AdminGuardService {
  static final _supabase = Supabase.instance.client;
  static bool? _cachedResult;
  static String? _cachedRole;

  /// Check if current user is an admin
  static Future<bool> isAdmin() async {
    if (_cachedResult != null) return _cachedResult!;

    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) {
        _cachedResult = false;
        return false;
      }

      final response = await _supabase
          .from('admin_access')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      _cachedResult = response != null;

      if (kDebugMode) {
        print(
          '🔐 Admin check: $email → ${_cachedResult! ? "✅ admin" : "❌ not admin"}',
        );
      }

      return _cachedResult!;
    } catch (e) {
      if (kDebugMode) print('⚠️ Admin check failed: $e');
      _cachedResult = false;
      return false; // Fail closed
    }
  }

  /// Clear cache (call on logout).
  static void clearCache() {
    _cachedResult = null;
    _cachedRole = null;
  }
}
