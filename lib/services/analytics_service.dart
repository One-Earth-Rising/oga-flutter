import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// OGA Analytics Service
/// Writes to `beta_analytics` table in Supabase.
/// All methods are fire-and-forget — analytics failures never block UI.
///
/// Usage:
///   await AnalyticsService.init();              // Call once at app start
///   AnalyticsService.trackPageView('dashboard'); // Track screens
///   AnalyticsService.trackFeature('character_viewed', {'character': 'ryu'});
///
/// Table: beta_analytics
///   id, user_email, event_type, event_data (jsonb), page_context, session_id, created_at
class AnalyticsService {
  static final _supabase = Supabase.instance.client;
  static String? _sessionId;
  static String? _userEmail;
  static DateTime? _sessionStart;
  static String? _currentPage;

  // ─── INITIALIZATION ───────────────────────────────────────

  /// Initialize analytics for the current user session.
  /// Call once after authentication succeeds.
  static Future<void> init() async {
    try {
      final user = _supabase.auth.currentUser;
      _userEmail = user?.email;
      _sessionId = const Uuid().v4();
      _sessionStart = DateTime.now();

      await _track(
        'session_start',
        data: {
          'platform': kIsWeb ? 'web' : 'native',
          'timestamp': _sessionStart!.toIso8601String(),
        },
      );

      if (kDebugMode) {
        print(
          '📊 Analytics initialized — session: ${_sessionId?.substring(0, 8)}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Analytics init failed: $e');
    }
  }

  /// End the current session. Call on logout or app dispose.
  static Future<void> endSession() async {
    if (_sessionStart == null) return;
    final duration = DateTime.now().difference(_sessionStart!).inSeconds;

    await _track(
      'session_end',
      data: {
        'duration_seconds': duration,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    _sessionId = null;
    _sessionStart = null;
    _userEmail = null;
    _currentPage = null;

    if (kDebugMode) {
      print('📊 Analytics session ended — duration: ${duration}s');
    }
  }

  // ─── PAGE TRACKING ────────────────────────────────────────

  /// Track a page/screen view.
  /// [pageName] should be a consistent key like 'dashboard', 'character_detail', 'friends'.
  static Future<void> trackPageView(
    String pageName, {
    Map<String, dynamic>? extra,
  }) async {
    _currentPage = pageName;
    await _track('page_view', page: pageName, data: extra);
  }

  // ─── FEATURE TRACKING ────────────────────────────────────

  /// Track a feature interaction.
  /// [feature] — e.g. 'character_viewed', 'share_tapped', 'friend_added'
  /// [data] — optional metadata like {'character_id': 'ryu', 'game': 'street_fighter'}
  static Future<void> trackFeature(
    String feature, [
    Map<String, dynamic>? data,
  ]) async {
    await _track(
      'feature_use',
      page: _currentPage,
      data: {'feature': feature, ...?data},
    );
  }

  // ─── CONVENIENCE METHODS ──────────────────────────────────

  /// Character was viewed in detail screen
  static Future<void> trackCharacterViewed(
    String characterId, {
    String? game,
    bool? owned,
  }) async {
    await trackFeature('character_viewed', {
      'character_id': characterId,
      if (game != null) 'game': game,
      if (owned != null) 'owned': owned,
    });
  }

  /// Share profile or character
  static Future<void> trackShareTapped({String? characterId}) async {
    await trackFeature('share_tapped', {
      'type': characterId != null ? 'character' : 'profile',
      if (characterId != null) 'character_id': characterId,
    });
  }

  /// Friend action (added, removed, request_sent)
  static Future<void> trackFriendAction(
    String action, {
    String? friendEmail,
  }) async {
    await trackFeature('friend_$action', {
      if (friendEmail != null) 'friend': friendEmail,
    });
  }

  /// Settings interaction
  static Future<void> trackSettingsAction(String action) async {
    await trackFeature('settings_$action');
  }

  /// Feedback submitted
  static Future<void> trackFeedbackSubmitted(String category) async {
    await trackFeature('feedback_submitted', {'category': category});
  }

  /// Tab switched
  static Future<void> trackTabSwitch(String tabName) async {
    await trackFeature('tab_switch', {'tab': tabName});
  }

  /// Grid/list view toggle
  static Future<void> trackViewToggle(bool isGridView) async {
    await trackFeature('view_toggle', {'mode': isGridView ? 'grid' : 'list'});
  }

  // ─── ERROR TRACKING ──────────────────────────────────────

  /// Track an error event
  static Future<void> trackError(String errorMessage, {String? context}) async {
    await _track(
      'error',
      page: _currentPage,
      data: {'error': errorMessage, if (context != null) 'context': context},
    );
  }

  // ─── INTERNAL ─────────────────────────────────────────────

  /// Core tracking method — writes to beta_analytics table.
  /// Fire-and-forget: wrapped in try-catch, never throws.
  static Future<void> _track(
    String eventType, {
    String? page,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Refresh email if we don't have it yet (late auth)
      _userEmail ??= _supabase.auth.currentUser?.email;
      if (_userEmail == null) return; // Can't track without user

      await _supabase.from('beta_analytics').insert({
        'user_email': _userEmail,
        'event_type': eventType,
        'event_data': data ?? {},
        'page_context': page ?? _currentPage,
        'session_id': _sessionId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Analytics track failed ($eventType): $e');
      }
      // Never rethrow — analytics must not break the app
    }
  }

  // ─── ADMIN QUERIES ────────────────────────────────────────
  // These methods are for the admin analytics screen.
  // They read from beta_analytics + invite_analytics + profiles.

  /// Get daily active users for the last N days
  static Future<List<Map<String, dynamic>>> getDailyActiveUsers({
    int days = 14,
  }) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toUtc()
          .toIso8601String();
      final response = await _supabase.rpc(
        'get_daily_active_users',
        params: {'since_date': since},
      );
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      if (kDebugMode) print('⚠️ getDailyActiveUsers failed: $e');
      return [];
    }
  }

  /// Get feature usage counts
  static Future<List<Map<String, dynamic>>> getFeatureUsage({
    int days = 7,
  }) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toUtc()
          .toIso8601String();
      final response = await _supabase.rpc(
        'get_feature_usage',
        params: {'since_date': since},
      );
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      if (kDebugMode) print('⚠️ getFeatureUsage failed: $e');
      return [];
    }
  }

  /// Get invite funnel data
  static Future<Map<String, int>> getInviteFunnel({int days = 30}) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toUtc()
          .toIso8601String();
      final response = await _supabase.rpc(
        'get_invite_funnel',
        params: {'since_date': since},
      );
      final list = List<Map<String, dynamic>>.from(response ?? []);
      final funnel = <String, int>{};
      for (final row in list) {
        funnel[row['event_type'] as String] = (row['count'] as num).toInt();
      }
      return funnel;
    } catch (e) {
      if (kDebugMode) print('⚠️ getInviteFunnel failed: $e');
      return {};
    }
  }

  /// Get active beta users (from beta_access table)
  static Future<List<Map<String, dynamic>>> getActiveBetaUsers() async {
    try {
      final response = await _supabase
          .from('beta_access')
          .select('email, notes, granted_at')
          .isFilter('revoked_at', null)
          .order('granted_at', ascending: false);
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      if (kDebugMode) print('⚠️ getActiveBetaUsers failed: $e');
      return [];
    }
  }

  /// Get recent events (live feed)
  static Future<List<Map<String, dynamic>>> getRecentEvents({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('beta_analytics')
          .select(
            'user_email, event_type, event_data, page_context, created_at',
          )
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      if (kDebugMode) print('⚠️ getRecentEvents failed: $e');
      return [];
    }
  }

  /// Get top viewed characters
  static Future<List<Map<String, dynamic>>> getTopCharacters({
    int days = 7,
  }) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toUtc()
          .toIso8601String();
      final response = await _supabase.rpc(
        'get_top_characters',
        params: {'since_date': since},
      );
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      if (kDebugMode) print('⚠️ getTopCharacters failed: $e');
      return [];
    }
  }

  /// Get average session duration in seconds
  static Future<double> getAvgSessionDuration({int days = 7}) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toUtc()
          .toIso8601String();
      final response = await _supabase.rpc(
        'get_avg_session_duration',
        params: {'since_date': since},
      );
      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) print('⚠️ getAvgSessionDuration failed: $e');
      return 0.0;
    }
  }

  // ─── GETTERS ──────────────────────────────────────────────

  static String? get currentSessionId => _sessionId;
  static String? get currentUserEmail => _userEmail;
  static String? get currentPage => _currentPage;
}
