import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight analytics event tracking for beta.
/// Fire-and-forget design — never blocks UI.
class AnalyticsService {
  static final _supabase = Supabase.instance.client;

  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ═══════════════════════════════════════════════════════════
  // EVENT TYPES (constants for consistency)
  // ═══════════════════════════════════════════════════════════

  static const String eventSignUp = 'sign_up';
  static const String eventSignIn = 'sign_in';
  static const String eventCharacterViewed = 'character_viewed';
  static const String eventShareGenerated = 'share_generated';
  static const String eventInviteAccepted = 'invite_accepted';
  static const String eventFeedbackSubmitted = 'feedback_submitted';
  static const String eventProfileUpdated = 'profile_updated';
  static const String eventFriendAdded = 'friend_added';
  static const String eventTradeRequested = 'trade_requested';
  static const String eventDashboardViewed = 'dashboard_viewed';
  static const String eventInviteLandingViewed = 'invite_landing_viewed';
  static const String eventOnboardingCompleted = 'onboarding_completed';

  // ═══════════════════════════════════════════════════════════
  // CORE TRACKING
  // ═══════════════════════════════════════════════════════════

  /// Track an event. Fire-and-forget — errors are logged, never thrown.
  /// [metadata] is optional key-value data (stored as JSONB).
  static Future<void> track(
    String eventType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('analytics_events').insert({
        'user_email': _currentEmail,
        'event_type': eventType,
        'metadata': metadata ?? {},
      });

      debugPrint(
        '📊 Event: $eventType ${metadata != null ? metadata.toString() : ''}',
      );
    } catch (e) {
      // Never block UI for analytics failures
      debugPrint('⚠️ Analytics error ($eventType): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CONVENIENCE METHODS
  // ═══════════════════════════════════════════════════════════

  /// Track character view with character details.
  static Future<void> trackCharacterView(
    String characterId, {
    bool isGuest = false,
  }) {
    return track(
      eventCharacterViewed,
      metadata: {'character_id': characterId, 'is_guest': isGuest},
    );
  }

  /// Track share generation with URL details.
  static Future<void> trackShare(String characterId, String inviteCode) {
    return track(
      eventShareGenerated,
      metadata: {'character_id': characterId, 'invite_code': inviteCode},
    );
  }

  /// Track invite landing page view (guest or authenticated).
  static Future<void> trackInviteLanding(
    String inviteCode, {
    String? characterId,
  }) {
    return track(
      eventInviteLandingViewed,
      metadata: {
        'invite_code': inviteCode,
        if (characterId != null) 'character_id': characterId,
      },
    );
  }

  /// Track dashboard load.
  static Future<void> trackDashboardView() {
    return track(eventDashboardViewed);
  }

  /// Track feedback submission.
  static Future<void> trackFeedback(String category) {
    return track(eventFeedbackSubmitted, metadata: {'category': category});
  }
}
