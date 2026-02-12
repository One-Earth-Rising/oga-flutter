import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Campaign feature flags for kill switch functionality
/// Allows instant enabling/disabling of campaigns via database
class CampaignFeatureFlags {
  static final supabase = Supabase.instance.client;

  // Cache flags to avoid excessive database calls
  static final Map<String, bool> _flagCache = {};
  static DateTime? _lastFetch;

  /// Check if campaign is enabled (with caching)
  /// Cache refreshes every 5 minutes
  static Future<bool> isCampaignEnabled(String campaignId) async {
    // Refresh cache every 5 minutes
    if (_lastFetch == null ||
        DateTime.now().difference(_lastFetch!) > const Duration(minutes: 5)) {
      await _refreshFlags();
    }

    return _flagCache[campaignId] ?? false;
  }

  /// Refresh campaign flags from database
  static Future<void> _refreshFlags() async {
    try {
      final response = await supabase
          .from('campaigns')
          .select('id, is_active')
          .eq('is_active', true);

      _flagCache.clear();
      for (final campaign in response) {
        _flagCache[campaign['id']] = campaign['is_active'];
      }

      _lastFetch = DateTime.now();
      if (kDebugMode) {
        print('✅ Campaign flags refreshed: $_flagCache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching campaign flags: $e');
      }
      // On error, disable all campaigns (fail-safe)
      _flagCache.clear();
    }
  }

  /// Force refresh flags (use after toggling campaign in database)
  static Future<void> forceRefresh() async {
    _lastFetch = null;
    await _refreshFlags();
  }
}
