import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing invite usage, limits, and tracking.
/// Works with the invite_usage table + profiles.invite_limit.
class InviteService {
  static final _supabase = Supabase.instance.client;

  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ═══════════════════════════════════════════════════════════
  // INVITE LIMIT CHECKS
  // ═══════════════════════════════════════════════════════════

  /// Check if the current user can still send invites.
  /// Returns {canSend, used, limit}.
  static Future<InviteQuota> getInviteQuota() async {
    final email = _currentEmail;
    if (email == null) {
      return const InviteQuota(canSend: false, used: 0, limit: 0);
    }

    try {
      // Get invite limit from profile
      final profile = await _supabase
          .from('profiles')
          .select('invite_limit')
          .eq('email', email)
          .maybeSingle();

      final limit = (profile?['invite_limit'] as int?) ?? 5;

      // Count shares sent
      final usage = await _supabase
          .from('invite_usage')
          .select('id')
          .eq('inviter_email', email);

      final used = (usage as List).length;

      return InviteQuota(canSend: used < limit, used: used, limit: limit);
    } catch (e) {
      debugPrint('❌ Error checking invite quota: $e');
      // Fail open during beta — don't block sharing on errors
      return const InviteQuota(canSend: true, used: 0, limit: 5);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // TRACK INVITE ACTIONS
  // ═══════════════════════════════════════════════════════════

  /// Record that a share link was generated.
  /// Call this when the user taps the share button.
  /// Returns the invite_usage row ID (for later status updates).
  static Future<int?> recordShare({
    required String inviteCode,
    String? characterId,
  }) async {
    final email = _currentEmail;
    if (email == null) return null;

    try {
      final result = await _supabase
          .from('invite_usage')
          .insert({
            'inviter_email': email,
            'invite_code': inviteCode,
            'character_id': characterId,
            'status': 'shared',
          })
          .select('id')
          .single();

      debugPrint('📊 Recorded share: code=$inviteCode, char=$characterId');
      return result['id'] as int?;
    } catch (e) {
      debugPrint('❌ Error recording share: $e');
      return null;
    }
  }

  /// Mark an invite as clicked (recipient opened the link).
  /// Called from InviteLandingScreen when a guest loads the page.
  static Future<void> recordClick({
    required String inviteCode,
    String? characterId,
  }) async {
    try {
      // Find the most recent unclicked share for this code + character
      final rows = await _supabase
          .from('invite_usage')
          .select('id')
          .eq('invite_code', inviteCode)
          .eq('status', 'shared')
          .order('created_at', ascending: false)
          .limit(1);

      if ((rows as List).isNotEmpty) {
        await _supabase
            .from('invite_usage')
            .update({
              'status': 'clicked',
              'clicked_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', rows[0]['id']);

        debugPrint('📊 Recorded click: code=$inviteCode');
      }
    } catch (e) {
      // Non-blocking — don't fail the user experience for tracking
      debugPrint('⚠️ Error recording click: $e');
    }
  }

  /// Mark an invite as converted (recipient signed up).
  /// Called from _getLandingPage after successful invite signup.
  static Future<void> recordConversion({
    required String inviteCode,
    required String inviteeEmail,
  }) async {
    try {
      // Find the most recent clicked (or shared) entry for this code
      final rows = await _supabase
          .from('invite_usage')
          .select('id')
          .eq('invite_code', inviteCode)
          .inFilter('status', ['clicked', 'shared'])
          .order('created_at', ascending: false)
          .limit(1);

      if ((rows as List).isNotEmpty) {
        await _supabase
            .from('invite_usage')
            .update({
              'status': 'converted',
              'invitee_email': inviteeEmail,
              'converted_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', rows[0]['id']);

        debugPrint('📊 Recorded conversion: $inviteeEmail via $inviteCode');
      }
    } catch (e) {
      debugPrint('⚠️ Error recording conversion: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // USAGE STATS (for profile / settings display)
  // ═══════════════════════════════════════════════════════════

  /// Get invite stats for the current user.
  static Future<InviteStats> getMyStats() async {
    final email = _currentEmail;
    if (email == null) {
      return const InviteStats(shared: 0, clicked: 0, converted: 0);
    }

    try {
      final rows = await _supabase
          .from('invite_usage')
          .select('status')
          .eq('inviter_email', email);

      int shared = 0, clicked = 0, converted = 0;
      for (final row in rows) {
        switch (row['status']) {
          case 'shared':
            shared++;
            break;
          case 'clicked':
            clicked++;
            break;
          case 'converted':
            converted++;
            break;
        }
      }

      return InviteStats(
        shared: shared + clicked + converted, // total shares
        clicked: clicked + converted, // clicked includes converted
        converted: converted,
      );
    } catch (e) {
      debugPrint('❌ Error fetching invite stats: $e');
      return const InviteStats(shared: 0, clicked: 0, converted: 0);
    }
  }
}

/// Invite quota for the current user.
class InviteQuota {
  final bool canSend;
  final int used;
  final int limit;

  const InviteQuota({
    required this.canSend,
    required this.used,
    required this.limit,
  });

  int get remaining => (limit - used).clamp(0, limit);

  String get displayText => '$used / $limit invites used';
}

/// Invite usage statistics.
class InviteStats {
  final int shared;
  final int clicked;
  final int converted;

  const InviteStats({
    required this.shared,
    required this.clicked,
    required this.converted,
  });

  double get clickRate => shared > 0 ? clicked / shared : 0;
  double get conversionRate => shared > 0 ? converted / shared : 0;
}
