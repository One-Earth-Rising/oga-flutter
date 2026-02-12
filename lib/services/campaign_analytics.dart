import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Campaign analytics for tracking events and monitoring
/// Logs campaign-related events for analysis and debugging
class CampaignAnalytics {
  static final supabase = Supabase.instance.client;

  /// Log a campaign event
  static Future<void> logEvent(
    String event, {
    String? campaignId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await supabase.from('campaign_events').insert({
        'event_name': event,
        'campaign_id': campaignId,
        'session_id': sessionId,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to log event: $e');
      }
      // Don't throw - logging failure shouldn't break app
    }
  }

  /// Track when campaign loads
  static Future<void> trackCampaignLoad(String campaignId) async {
    await logEvent('campaign_load', campaignId: campaignId);
  }

  /// Track when campaign onboarding completes
  static Future<void> trackCampaignComplete(
    String sessionId,
    String campaignId,
  ) async {
    await logEvent(
      'campaign_complete',
      campaignId: campaignId,
      sessionId: sessionId,
    );
  }

  /// Track campaign errors
  static Future<void> trackCampaignError(
    String error,
    String? campaignId,
  ) async {
    await logEvent(
      'campaign_error',
      campaignId: campaignId,
      metadata: {'error': error},
    );
  }
}
