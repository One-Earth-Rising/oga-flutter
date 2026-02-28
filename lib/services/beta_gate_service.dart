import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to check whether the current user has beta access.
///
/// Queries the `beta_access` table (created in Sprint 11A migrations).
/// Access is granted when:
///   - email exists in beta_access
///   - revoked_at IS NULL
///
/// Usage in routing:
///   final hasAccess = await BetaGateService.hasAccess();
///   if (!hasAccess) return BetaWaitlistScreen();
class BetaGateService {
  static final _supabase = Supabase.instance.client;

  /// Check if the current authenticated user has active beta access.
  /// Returns true if user is in the beta_access table with no revocation.
  /// Returns false if not found, revoked, or on error.
  static Future<bool> hasAccess() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        debugPrint('🚫 BetaGate: No authenticated user');
        return false;
      }

      final email = user.email!;
      debugPrint('🔐 BetaGate: Checking access for $email');

      final response = await _supabase
          .from('beta_access')
          .select('email, revoked_at')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        debugPrint('🚫 BetaGate: $email not in beta_access table');
        return false;
      }

      final revokedAt = response['revoked_at'];
      if (revokedAt != null) {
        debugPrint('🚫 BetaGate: $email access revoked at $revokedAt');
        return false;
      }

      debugPrint('✅ BetaGate: $email has active beta access');
      return true;
    } catch (e) {
      debugPrint('❌ BetaGate: Error checking access — $e');
      // FAIL CLOSED: If we can't verify, deny access.
      // This is intentional for beta — we want controlled access.
      return false;
    }
  }

  /// Quick admin helper: grant beta access via Supabase.
  /// Only works with service role key (not from client).
  /// Use Supabase SQL Editor instead:
  ///
  /// INSERT INTO beta_access (email, granted_by, notes)
  /// VALUES ('tester@example.com', 'jan@oneearthrising.com', 'Discord: tester#1234');
  ///
  /// To revoke:
  /// UPDATE beta_access SET revoked_at = now() WHERE email = 'tester@example.com';
  ///
  /// To list active testers:
  /// SELECT email, notes, granted_at FROM beta_access WHERE revoked_at IS NULL;
}
