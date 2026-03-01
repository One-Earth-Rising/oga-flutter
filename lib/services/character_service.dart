// ═══════════════════════════════════════════════════════════════════
// CHARACTER SERVICE — Sprint 12 (Supabase Catalog)
// Replaces hardcoded character data with live Supabase queries.
// Caches in memory for fast access during a session.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oga_character.dart';

class CharacterService {
  static final _supabase = Supabase.instance.client;

  // ─── In-memory cache ──────────────────────────────────────
  static List<OGACharacter>? _cache;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  /// Get all active characters from catalog.
  /// Returns cached data if available and fresh.
  static Future<List<OGACharacter>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    try {
      _cache = await _fetchFromSupabase();
      _cacheTime = DateTime.now();
      // Sync static cache for compatibility (fromId, allCharacters)
      OGACharacter.updateCache(_cache!);
      return _cache!;
    } catch (e) {
      debugPrint('❌ CharacterService.getAll error: $e');
      // Return cache if available, even if stale
      if (_cache != null) return _cache!;
      return [];
    }
  }

  /// Get a single character by ID.
  static Future<OGACharacter?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Force refresh the cache (e.g. after admin adds a character).
  static Future<void> refreshCache() async {
    await getAll(forceRefresh: true);
  }

  /// Clear cache (e.g. on logout).
  static void clearCache() {
    _cache = null;
    _cacheTime = null;
    OGACharacter.updateCache([]);
  }

  /// Synchronous access to cached characters (for widgets that
  /// can't await). Returns empty list if cache isn't loaded yet.
  static List<OGACharacter> get cached => _cache ?? [];

  /// Synchronous lookup by ID from cache.
  static OGACharacter? cachedById(String id) {
    if (_cache == null) return null;
    try {
      return _cache!.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Private: fetch full catalog from Supabase ────────────

  static Future<List<OGACharacter>> _fetchFromSupabase() async {
    // Fetch all tables in parallel
    final results = await Future.wait([
      _supabase
          .from('characters')
          .select()
          .eq('is_active', true)
          .order('sort_order'),
      _supabase.from('character_variations').select().order('sort_order'),
      _supabase.from('character_rewards').select().order('sort_order'),
      _supabase.from('character_gameplay').select().order('sort_order'),
      _supabase.from('portal_passes').select().eq('is_active', true),
      _supabase.from('portal_pass_tasks').select().order('sort_order'),
      _supabase.from('portal_pass_rewards').select().order('sort_order'),
    ]);

    final charRows = results[0] as List;
    final variationRows = results[1] as List;
    final rewardRows = results[2] as List;
    final gameplayRows = results[3] as List;
    final passRows = results[4] as List;
    final taskRows = results[5] as List;
    final passRewardRows = results[6] as List;

    // Group sub-data by character_id / pass_id
    final variationsByChar = _groupBy(variationRows, 'character_id');
    final rewardsByChar = _groupBy(rewardRows, 'character_id');
    final gameplayByChar = _groupBy(gameplayRows, 'character_id');
    final passesByChar = _groupBy(passRows, 'character_id');
    final tasksByPass = _groupBy(taskRows, 'pass_id');
    final rewardsByPass = _groupBy(passRewardRows, 'pass_id');

    // Build OGACharacter list
    final characters = <OGACharacter>[];

    for (final row in charRows) {
      final charId = row['id'] as String;

      // Build variations
      final variations = (variationsByChar[charId] ?? [])
          .map<GameVariation>(
            (v) => GameVariation(
              gameId: v['game_id'] ?? '',
              gameName: v['game_name'] ?? '',
              gameIcon: v['game_icon'] ?? '',
              characterImage: v['character_image'] ?? '',
              engineName: v['engine_name'] ?? '',
              description: v['description'] ?? '',
            ),
          )
          .toList();

      // Build rewards
      final rewards = (rewardsByChar[charId] ?? [])
          .map<SpecialReward>(
            (r) => SpecialReward(
              id: r['id'] ?? '',
              name: r['name'] ?? '',
              image: r['image'] ?? '',
              description: r['description'] ?? '',
              rarity: r['rarity'] ?? 'Common',
            ),
          )
          .toList();

      // Build gameplay
      final gameplay = (gameplayByChar[charId] ?? [])
          .map<GameplayMedia>(
            (g) => GameplayMedia(
              id: g['id'] ?? '',
              imageUrl: g['image_url'] ?? '',
              videoUrl: g['video_url'] as String?,
              caption: g['caption'] ?? '',
              gameName: g['game_name'] ?? '',
            ),
          )
          .toList();

      // Build portal pass (take first active pass for this character)
      PortalPass? portalPass;
      final passes = passesByChar[charId] ?? [];
      if (passes.isNotEmpty) {
        final p = passes.first;
        final passId = p['id'] as String;

        final tasks = (tasksByPass[passId] ?? [])
            .map<PortalPassTask>(
              (t) => PortalPassTask(
                id: t['id'] ?? '',
                title: t['title'] ?? '',
                description: t['description'] ?? '',
                targetGame: t['target_game'] ?? '',
                currentProgress: t['current_progress'] ?? 0,
                targetProgress: t['target_progress'] ?? 1,
                xpReward: t['xp_reward'] ?? 0,
                isCompleted: t['is_completed'] ?? false,
              ),
            )
            .toList();

        final passRewards = (rewardsByPass[passId] ?? [])
            .map<PortalPassReward>(
              (r) => PortalPassReward(
                id: r['id'] ?? '',
                name: r['name'] ?? '',
                image: r['image'] ?? '',
                levelRequired: r['level_required'] ?? 0,
                isUnlocked: r['is_unlocked'] ?? false,
              ),
            )
            .toList();

        portalPass = PortalPass(
          id: passId,
          name: p['name'] ?? '',
          description: p['description'] ?? '',
          currentLevel: p['current_level'] ?? 0,
          maxLevel: p['max_level'] ?? 50,
          progressPercent: (p['progress_percent'] ?? 0.0).toDouble(),
          expiresAt: p['expires_at'] != null
              ? DateTime.tryParse(p['expires_at'].toString())
              : null,
          tasks: tasks,
          rewards: passRewards,
        );
      }

      // Parse accent color
      Color accentColor = const Color(0xFF121212);
      final colorStr = row['accent_color'] as String?;
      if (colorStr != null &&
          colorStr.startsWith('#') &&
          colorStr.length == 7) {
        accentColor = Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      }

      // Parse tags
      final tags =
          (row['tags'] as List?)?.map<String>((t) => t.toString()).toList() ??
          [];

      characters.add(
        OGACharacter(
          id: charId,
          name: row['name'] ?? '',
          ip: row['ip'] ?? '',
          description: row['description'] ?? '',
          lore: row['lore'] ?? '',
          heroImage: row['hero_image'] ?? '',
          silhouetteImage: row['silhouette_image'] ?? '',
          thumbnailImage: row['thumbnail_image'] ?? '',
          rarity: row['rarity'] ?? 'Common',
          characterClass: row['character_class'] ?? '',
          tags: tags,
          accentColorOverride: accentColor,
          gameVariations: variations,
          portalPass: portalPass,
          specialRewards: rewards,
          gameplayMedia: gameplay,
          // ownership fields are set later by OwnershipService
          isOwned: false,
          progress: 0.0,
          ownershipHistory: const [],
        ),
      );
    }

    debugPrint('✅ CharacterService: loaded ${characters.length} characters');
    return characters;
  }

  /// Group a list of maps by a key field.
  static Map<String, List<Map<String, dynamic>>> _groupBy(
    List rows,
    String key,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final k = row[key]?.toString() ?? '';
      map.putIfAbsent(k, () => []).add(Map<String, dynamic>.from(row));
    }
    return map;
  }
}
