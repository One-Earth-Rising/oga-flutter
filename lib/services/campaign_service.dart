import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campaign_config.dart';

/// Campaign service for managing campaign logic
/// Handles campaign detection, validation, and user association
class CampaignService {
  static final supabase = Supabase.instance.client;

  /// Get campaign ID from URL (web only)
  static String? getCampaignFromUrl() {
    if (kIsWeb) {
      final uri = Uri.base;

      // Check ?campaign=fbs_launch query parameter
      if (uri.queryParameters.containsKey('campaign')) {
        return uri.queryParameters['campaign'];
      }

      // Check /fbs path
      if (uri.path.startsWith('/fbs')) {
        return 'fbs_launch';
      }
    }
    return null;
  }

  /// Get campaign ID safely with validation (async version)
  static Future<String?> getSafeCampaignId() async {
    try {
      final campaignId = getCampaignFromUrl();
      if (campaignId == null) return null;

      // Verify campaign exists and is active
      final isValid = await _validateCampaign(campaignId);
      if (!isValid) {
        if (kDebugMode) {
          print('⚠️ Campaign $campaignId is invalid, using main');
        }
        return null;
      }

      return campaignId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting campaign: $e');
      }
      return null; // Fail-safe: return main
    }
  }

  /// Validate that campaign exists and is active
  static Future<bool> _validateCampaign(String campaignId) async {
    try {
      final response = await supabase
          .from('campaigns')
          .select('is_active')
          .eq('id', campaignId)
          .single();

      return response['is_active'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Campaign validation error: $e');
      }
      return false; // Fail-safe: campaign doesn't exist
    }
  }

  /// Save campaign to user profile with retries
  static Future<void> saveCampaignToUser(
    String sessionId,
    String? campaignId, {
    int maxRetries = 3,
  }) async {
    if (campaignId == null || campaignId == 'main') return;

    for (int i = 0; i < maxRetries; i++) {
      try {
        await supabase
            .from('profiles')
            .update({
              'campaign_id': campaignId,
              'campaign_joined_at': DateTime.now().toIso8601String(),
            })
            .eq('session_id', sessionId);

        if (kDebugMode) {
          print('✅ Saved campaign (attempt ${i + 1})');
        }
        return; // Success
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error saving campaign (attempt ${i + 1}): $e');
        }
        if (i == maxRetries - 1) {
          // Last attempt failed - log but don't crash
          if (kDebugMode) {
            print('⚠️ Failed to save campaign after $maxRetries attempts');
          }
        } else {
          await Future.delayed(const Duration(seconds: 1)); // Wait before retry
        }
      }
    }
  }

  /// Get campaign config
  static CampaignConfig getConfig(String? campaignId) {
    return CampaignConfig.fromId(campaignId);
  }
}
