import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

class PortalPassData {
  final String id;
  final String slug;
  final String name;
  final String type; // brand_campaign | external_ip | game_asset
  final String? brandName;
  final String? brandLogoUrl;
  final String? seasonName;
  final String? description;
  final DateTime? expiresAt;
  final String? specialRewardName;
  final String? specialRewardDescription;
  final String? specialRewardImageUrl;
  final String? specialRewardCharacterId;
  final List<PortalPassTaskData> tasks;

  const PortalPassData({
    required this.id,
    required this.slug,
    required this.name,
    required this.type,
    this.brandName,
    this.brandLogoUrl,
    this.seasonName,
    this.description,
    this.expiresAt,
    this.specialRewardName,
    this.specialRewardDescription,
    this.specialRewardImageUrl,
    this.specialRewardCharacterId,
    required this.tasks,
  });

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.isCompleted).length;
  double get progressPercent =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
  bool get isComplete => totalTasks > 0 && completedTasks == totalTasks;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get expiryLabel {
    if (expiresAt == null) return '';
    if (isExpired) return 'EXPIRED';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.inDays > 60) {
      const months = [
        '',
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return 'EXPIRES ${months[expiresAt!.month]} ${expiresAt!.day}, ${expiresAt!.year}';
    }
    if (diff.inDays > 0) return '${diff.inDays}D LEFT';
    if (diff.inHours > 0) return '${diff.inHours}H LEFT';
    return '${diff.inMinutes}M LEFT';
  }
}

class PortalPassTaskData {
  final String id;
  final String title;
  final String? description;
  final String taskType;
  final String? targetCharacterId;
  final String? targetValue;
  final int xpReward;
  final int orderIndex;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedVia;

  const PortalPassTaskData({
    required this.id,
    required this.title,
    this.description,
    required this.taskType,
    this.targetCharacterId,
    this.targetValue,
    required this.xpReward,
    required this.orderIndex,
    required this.isCompleted,
    this.completedAt,
    this.completedVia,
  });
}

// ═══════════════════════════════════════════════════════════════
// SERVICE
// ═══════════════════════════════════════════════════════════════

class PortalPassService {
  static final _supabase = Supabase.instance.client;
  static final _cache = <String, PortalPassData?>{};

  /// Loads the portal pass assigned to [characterId], including the
  /// authenticated user's task completion progress.
  /// Returns null if no pass is assigned.
  static Future<PortalPassData?> getForCharacter(String characterId) async {
    if (_cache.containsKey(characterId)) return _cache[characterId];

    try {
      final userEmail = _supabase.auth.currentUser?.email;

      // 1. Resolve pass_id for this character via portal_pass_tasks
      final assignRow = await _supabase
          .from('portal_pass_tasks')
          .select('pass_id')
          .eq('target_character_id', characterId)
          .limit(1)
          .maybeSingle();
      debugPrint('🎫 assignRow for $characterId: $assignRow');
      if (assignRow == null) {
        _cache[characterId] = null;
        return null;
      }
      final passId = assignRow['pass_id'] as String;

      // 2. Load pass template
      final passRow = await _supabase
          .from('portal_passes')
          .select()
          .eq('id', passId)
          .single();

      // 3. Load tasks ordered by index
      final taskRows = await _supabase
          .from('portal_pass_tasks')
          .select()
          .eq('pass_id', passId)
          .order('order_index');

      // 4. Load user progress (authenticated only)
      final completedMap = <String, Map<String, dynamic>>{};
      if (userEmail != null) {
        final progressRows = await _supabase
            .from('user_pass_progress')
            .select()
            .eq('user_email', userEmail)
            .eq('pass_id', passId);
        for (final p in progressRows) {
          completedMap[p['task_id'] as String] = p;
        }
      }

      // 5. Build task models
      final tasks = (taskRows as List<dynamic>).map((t) {
        final taskId = t['id'] as String;
        final progress = completedMap[taskId];
        return PortalPassTaskData(
          id: taskId,
          title: t['title'] as String,
          description: t['description'] as String?,
          taskType: t['task_type'] as String,
          targetCharacterId: t['target_character_id'] as String?,
          targetValue: t['target_value'] as String?,
          xpReward: t['xp_reward'] as int? ?? 100,
          orderIndex: t['order_index'] as int? ?? 0,
          isCompleted: progress != null,
          completedAt: progress != null && progress['completed_at'] != null
              ? DateTime.tryParse(progress['completed_at'] as String)
              : null,
          completedVia: progress?['completed_via'] as String?,
        );
      }).toList();

      final result = PortalPassData(
        id: passId,
        slug: passRow['slug'] as String,
        name: passRow['name'] as String,
        type: passRow['type'] as String,
        brandName: passRow['brand_name'] as String?,
        brandLogoUrl: passRow['brand_logo_url'] as String?,
        seasonName: passRow['season_name'] as String?,
        description: passRow['description'] as String?,
        expiresAt: passRow['expires_at'] != null
            ? DateTime.tryParse(passRow['expires_at'] as String)
            : null,
        specialRewardName: passRow['special_reward_name'] as String?,
        specialRewardDescription:
            passRow['special_reward_description'] as String?,
        specialRewardImageUrl: passRow['special_reward_image_url'] as String?,
        specialRewardCharacterId:
            passRow['special_reward_character_id'] as String?,
        tasks: tasks,
      );

      _cache[characterId] = result;
      return result;
    } catch (e) {
      debugPrint('⚠️ PortalPassService.getForCharacter($characterId): $e');
      _cache[characterId] = null;
      return null;
    }
  }

  /// Invalidate cache for one character (call after acquiring / trading).
  static void invalidateCache(String characterId) => _cache.remove(characterId);

  /// Clear entire cache (call on logout).
  static void clearCache() => _cache.clear();
}
