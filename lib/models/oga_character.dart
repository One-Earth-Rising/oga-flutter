// ═══════════════════════════════════════════════════════════════════
// OGA CHARACTER MODEL — Sprint 12 (Supabase Catalog)
//
// Data classes for character display. Populated from Supabase via
// CharacterService. No hardcoded character data.
//
// All image paths are RELATIVE to Supabase Storage 'characters' bucket.
// Resolved to full URLs via OgaStorage.resolve() at render time.
// ═══════════════════════════════════════════════════════════════════

import 'dart:ui' show Color;

// ─── Compatibility shim ─────────────────────────────────────
// Top-level function used by oga_account_dashboard_main.dart
// Delegates to CharacterService cache. Returns empty list if
// cache isn't loaded yet (caller should await getDisplayCharacters).
// Import this: import '../models/oga_character.dart';
List<OGACharacter> getAllCharactersSorted() {
  return OGACharacter.allCharacters;
}

class OGACharacter {
  final String id;
  final String name;
  final String ip;
  final String description;
  final String lore;
  final String heroImage;
  final String silhouetteImage;
  final String thumbnailImage;
  final String rarity;
  final String characterClass;
  final List<String> tags;
  final List<GameVariation> gameVariations;
  final PortalPass? portalPass;
  final List<SpecialReward> specialRewards;
  final List<PreviousOwner> ownershipHistory;
  final List<GameplayMedia> gameplayMedia;
  final bool isOwned;
  final bool isBorrowed;
  final bool isLentOut;
  final DateTime? acquiredDate;
  final double progress;
  final Color? accentColorOverride;

  const OGACharacter({
    required this.id,
    required this.name,
    required this.ip,
    required this.description,
    this.lore = '',
    required this.heroImage,
    this.silhouetteImage = '',
    this.thumbnailImage = '',
    this.rarity = 'Common',
    this.characterClass = '',
    this.tags = const [],
    this.gameVariations = const [],
    this.portalPass,
    this.specialRewards = const [],
    this.ownershipHistory = const [],
    this.gameplayMedia = const [],
    this.isOwned = false,
    this.isBorrowed = false,
    this.isLentOut = false,
    this.acquiredDate,
    this.progress = 0.0,
    this.accentColorOverride,
  });

  String get imagePath => heroImage;

  // ─── Static compatibility (delegates to CharacterService cache) ──
  // These exist so screens that used the old hardcoded model
  // keep compiling. They read from CharacterService's in-memory cache.
  // Import CharacterService in files that call these if not already imported.

  static List<OGACharacter> get allCharacters {
    // Lazy import avoidance: access via a late-bound reference.
    // CharacterService.cached is synchronous and returns [] if not loaded.
    try {
      return _cachedCharacters ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Set by CharacterService after fetching from Supabase.
  /// This avoids a circular import between oga_character.dart ↔ character_service.dart.
  static List<OGACharacter>? _cachedCharacters;

  /// Called by CharacterService to update the static cache.
  static void updateCache(List<OGACharacter> characters) {
    _cachedCharacters = characters;
  }

  /// Look up a character by ID from the static cache.
  /// Returns a placeholder if not found (prevents crashes).
  static OGACharacter fromId(String? id) {
    if (id == null || id.isEmpty) {
      return OGACharacter(
        id: 'unknown',
        name: 'UNKNOWN',
        ip: 'Unknown',
        description: 'No character selected',
        heroImage: '',
      );
    }
    final cached = allCharacters;
    try {
      return cached.firstWhere((c) => c.id == id);
    } catch (_) {
      // Return a minimal placeholder so screens don't crash
      return OGACharacter(
        id: id,
        name: id.toUpperCase(),
        ip: 'Unknown',
        description: 'Character data loading...',
        heroImage: '',
      );
    }
  }

  Color get accentColor {
    if (accentColorOverride != null) return accentColorOverride!;
    // Fallback for any edge case where override isn't set
    switch (id) {
      case 'ryu':
        return const Color(0xFFCC3333);
      case 'vegeta':
        return const Color(0xFF1A6BCC);
      case 'guggimon':
        return const Color(0xFF6B3FA0);
      default:
        return const Color(0xFF121212);
    }
  }

  Color get glowColor {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return const Color(0xFFAB47BC);
      case 'rare':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF2C2C2C);
    }
  }

  /// Card background tint color (alias for accentColor).
  Color get cardColor => accentColor;

  /// Create a copy with overridden ownership fields.
  /// Used by OwnershipService.getDisplayCharacters() to overlay
  /// per-user ownership onto the shared catalog.
  OGACharacter copyWith({
    bool? isOwned,
    bool? isBorrowed,
    bool? isLentOut,
    DateTime? acquiredDate,
    double? progress,
    List<PreviousOwner>? ownershipHistory,
  }) {
    return OGACharacter(
      id: id,
      name: name,
      ip: ip,
      description: description,
      lore: lore,
      heroImage: heroImage,
      silhouetteImage: silhouetteImage,
      thumbnailImage: thumbnailImage,
      rarity: rarity,
      characterClass: characterClass,
      tags: tags,
      gameVariations: gameVariations,
      portalPass: portalPass,
      specialRewards: specialRewards,
      ownershipHistory: ownershipHistory ?? this.ownershipHistory,
      gameplayMedia: gameplayMedia,
      isOwned: isOwned ?? this.isOwned,
      isBorrowed: isBorrowed ?? this.isBorrowed,
      isLentOut: isLentOut ?? this.isLentOut,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      progress: progress ?? this.progress,
      accentColorOverride: accentColorOverride,
    );
  }
}

class GameVariation {
  final String gameId;
  final String gameName;
  final String gameIcon;
  final String characterImage;
  final String engineName;
  final String description;
  const GameVariation({
    required this.gameId,
    required this.gameName,
    this.gameIcon = '',
    required this.characterImage,
    this.engineName = '',
    this.description = '',
  });
}

class PortalPass {
  final String id;
  final String name;
  final String description;
  final int currentLevel;
  final int maxLevel;
  final double progressPercent;
  final List<PortalPassTask> tasks;
  final List<PortalPassReward> rewards;
  final DateTime? expiresAt;
  const PortalPass({
    required this.id,
    required this.name,
    this.description = '',
    this.currentLevel = 0,
    this.maxLevel = 50,
    this.progressPercent = 0.0,
    this.tasks = const [],
    this.rewards = const [],
    this.expiresAt,
  });
}

class PortalPassTask {
  final String id;
  final String title;
  final String description;
  final String targetGame;
  final int currentProgress;
  final int targetProgress;
  final int xpReward;
  final bool isCompleted;
  const PortalPassTask({
    required this.id,
    required this.title,
    this.description = '',
    this.targetGame = '',
    this.currentProgress = 0,
    this.targetProgress = 1,
    this.xpReward = 0,
    this.isCompleted = false,
  });
  double get progressPercent =>
      targetProgress > 0 ? currentProgress / targetProgress : 0.0;
}

class PortalPassReward {
  final String id;
  final String name;
  final String image;
  final int levelRequired;
  final bool isUnlocked;
  const PortalPassReward({
    required this.id,
    required this.name,
    required this.image,
    this.levelRequired = 0,
    this.isUnlocked = false,
  });
}

class SpecialReward {
  final String id;
  final String name;
  final String image;
  final String description;
  final bool isUnlocked;
  final String rarity;
  const SpecialReward({
    required this.id,
    required this.name,
    required this.image,
    this.description = '',
    this.isUnlocked = false,
    this.rarity = 'Common',
  });
}

class PreviousOwner {
  final String username;
  final String? avatarUrl;
  final DateTime ownedFrom;
  final DateTime? ownedUntil;
  const PreviousOwner({
    required this.username,
    this.avatarUrl,
    required this.ownedFrom,
    this.ownedUntil,
  });
  bool get isCurrent => ownedUntil == null;
}

class GameplayMedia {
  final String id;
  final String imageUrl;
  final String? videoUrl;
  final String caption;
  final String gameName;
  const GameplayMedia({
    required this.id,
    required this.imageUrl,
    this.videoUrl,
    this.caption = '',
    this.gameName = '',
  });
}
