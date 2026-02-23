// ═══════════════════════════════════════════════════════════════════
// OGA CHARACTER MODEL — Sprint 8B
// ═══════════════════════════════════════════════════════════════════
import 'dart:ui' show Color;
// Architecture: Hardcoded MVP data with clear DB-migration markers.
//
// DATA SOURCE LEGEND:
//   [CONTAINER] → Will come from OGA PNG container metadata
//   [PORTAL]    → Will come from Portal Pass purchase/attachment
//   [SUPABASE]  → Will come from Supabase database
//   [COMPUTED]  → Derived at runtime from other sources
//
// ACQUISITION PATHS:
//   A) Single OGA purchase → character + images + description in container
//   B) Portal Pass purchase → character + pass + tasks + rewards
//   Both paths deliver all display data; the UI renders identically.
// ═══════════════════════════════════════════════════════════════════

/// The core character/asset model.
/// Each OGACharacter represents one Ownable Game Asset with all its
/// cross-game variations, attached passes, and ownership chain.
class OGACharacter {
  // ─── Core Identity [CONTAINER] ────────────────────────────
  final String id;
  final String name;
  final String ip; // IP franchise (e.g., "Street Fighter")
  final String description;
  final String lore; // Extended backstory
  final String heroImage; // Primary full-bleed character art
  final String silhouetteImage; // Dramatic backlit version (for hero bg)
  final String thumbnailImage; // Small card/list thumbnail

  // ─── Classification [CONTAINER] ───────────────────────────
  final String rarity; // 'Common', 'Rare', 'Epic', 'Legendary'
  final String characterClass; // 'Warrior', 'Mage', etc.
  final List<String> tags; // Searchable tags

  // ─── Game Variations [CONTAINER] ──────────────────────────
  final List<GameVariation> gameVariations;

  // ─── Portal Pass [PORTAL] ─────────────────────────────────
  final PortalPass? portalPass; // null = no pass attached

  // ─── Special Rewards [CONTAINER + PORTAL] ─────────────────
  final List<SpecialReward> specialRewards;

  // ─── Ownership [SUPABASE] ─────────────────────────────────
  final List<PreviousOwner> ownershipHistory;

  // ─── Gameplay Media [CONTAINER] ───────────────────────────
  final List<GameplayMedia> gameplayMedia;

  // ─── User State [SUPABASE / COMPUTED] ─────────────────────
  final bool isOwned;
  final DateTime? acquiredDate;
  final double progress; // 0.0–1.0 overall completion [COMPUTED]

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
    this.acquiredDate,
    this.progress = 0.0,
  });

  // ═══════════════════════════════════════════════════════════
  // BACKWARD-COMPATIBLE GETTERS
  // These map old property names used in invite_landing_screen,
  // invite_character_detail, character_card, etc. to the new model.
  // Remove these once all screens are migrated to new field names.
  // ═══════════════════════════════════════════════════════════

  /// Legacy alias for heroImage (used by invite screens, cards, dashboard)
  String get imagePath => heroImage;

  /// Legacy alias: list of game names from variations
  List<String> get availableGames =>
      gameVariations.map((v) => v.gameName).toList();

  /// Per-character brand color (used for card backgrounds, avatar borders)
  Color get cardColor {
    switch (id) {
      case 'ryu':
        return const Color(0xFFCC2200);
      case 'vegeta':
        return const Color(0xFF1A6BCC);
      case 'guggimon':
        return const Color(0xFF6B3FA0);
      default:
        return const Color(0xFF121212);
    }
  }

  /// Rarity-based glow color (used for owned card borders, hero glow)
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

  // ─── Static accessors (legacy API) ────────────────────────

  /// All characters sorted (owned first). Replaces OGACharacter.allCharacters.
  static List<OGACharacter> get allCharacters => getAllCharactersSorted();

  /// Find character by ID. Replaces OGACharacter.fromId().
  static OGACharacter fromId(String? id) =>
      findCharacterById(id ?? 'ryu') ?? hardcodedCharacters.first;
}

/// A character rendered for a specific game engine / title.
class GameVariation {
  final String gameId;
  final String gameName; // "Fortnite", "Roblox", etc.
  final String gameIcon; // Game logo/icon URL
  final String characterImage; // Character in this game's style
  final String engineName; // "Unreal Engine 5", "Unity", etc.
  final String description; // Brief note about this variation
  // TODO [CONTAINER]: final String containerFileUrl;

  const GameVariation({
    required this.gameId,
    required this.gameName,
    this.gameIcon = '',
    required this.characterImage,
    this.engineName = '',
    this.description = '',
  });
}

/// Portal Pass attached to a character — tracks cross-game progression.
class PortalPass {
  final String id;
  final String name; // "Season 1: Origins"
  final String description;
  final int currentLevel;
  final int maxLevel;
  final double progressPercent; // 0.0–1.0
  final List<PortalPassTask> tasks;
  final List<PortalPassReward> rewards;
  final DateTime? expiresAt;
  // TODO [PORTAL]: final String passContainerUrl;

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

/// A single task within a Portal Pass.
class PortalPassTask {
  final String id;
  final String title;
  final String description;
  final String targetGame; // Which game this task is for
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

/// A reward unlocked via Portal Pass progression or special achievement.
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

/// Special rewards tied to the character (skins, abilities, items).
class SpecialReward {
  final String id;
  final String name;
  final String image;
  final String description;
  final bool isUnlocked;
  final String rarity; // Matches character rarity system

  const SpecialReward({
    required this.id,
    required this.name,
    required this.image,
    this.description = '',
    this.isUnlocked = false,
    this.rarity = 'Common',
  });
}

/// An entry in the character's ownership chain.
class PreviousOwner {
  final String username;
  final String? avatarUrl;
  final DateTime ownedFrom;
  final DateTime? ownedUntil; // null = current owner

  const PreviousOwner({
    required this.username,
    this.avatarUrl,
    required this.ownedFrom,
    this.ownedUntil,
  });

  bool get isCurrent => ownedUntil == null;
}

/// Gameplay screenshots/videos showing the character in action.
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

// ═══════════════════════════════════════════════════════════════════
// HARDCODED MVP DATA
// ═══════════════════════════════════════════════════════════════════
// TODO [SUPABASE]: Replace with Supabase queries + OGA container parsing.
// When migrating, each character's core data comes from the PNG container,
// ownership from the `character_ownership` table, Portal Pass from
// `portal_passes` + `portal_pass_tasks`, and user state from `profiles`.
// ═══════════════════════════════════════════════════════════════════

final List<OGACharacter> hardcodedCharacters = [
  // ─── RYU ──────────────────────────────────────────────────
  OGACharacter(
    id: 'ryu',
    name: 'Ryu',
    ip: 'Street Fighter',
    description:
        'A disciplined martial artist seeking true strength, Ryu is a master '
        'of Ansatsuken, blending powerful strikes, fluid movement, and '
        'precise technique.',
    lore:
        'His iconic Hadouken energy blast controls space, while the '
        'Shoryuken uppercut delivers crushing power. The Tatsumaki '
        'Senpukyaku spinning kick keeps opponents on edge. '
        'Balanced and adaptable, Ryu is perfect for players who value '
        'skill and mastery.',
    heroImage: 'assets/characters/ryu_hero.png',
    silhouetteImage: 'assets/characters/ryu_silhouette.png',
    thumbnailImage: 'assets/characters/ryu_thumb.png',
    rarity: 'Legendary',
    characterClass: 'Warrior',
    tags: ['fighting', 'martial-arts', 'classic', 'capcom'],
    isOwned: true,
    acquiredDate: DateTime(2026, 1, 15),
    progress: 0.72,
    gameVariations: [
      GameVariation(
        gameId: 'fortnite',
        gameName: 'Fortnite',
        gameIcon: 'assets/games/fortnite_icon.png',
        characterImage: 'assets/characters/ryu_fortnite.png',
        engineName: 'Unreal Engine 5',
        description: 'Battle Royale ready with signature gi and headband.',
      ),
      GameVariation(
        gameId: 'roblox',
        gameName: 'Roblox',
        gameIcon: 'assets/games/roblox_icon.png',
        characterImage: 'assets/characters/ryu_roblox.png',
        engineName: 'Roblox Engine',
        description: 'Blocky martial arts master with classic moves.',
      ),
      GameVariation(
        gameId: 'animal_crossing',
        gameName: 'Animal Crossing',
        gameIcon: 'assets/games/animal_crossing_icon.png',
        characterImage: 'assets/characters/ryu_animal_crossing.png',
        engineName: 'Nintendo Engine',
        description: 'Island life meets the World Warrior.',
      ),
      GameVariation(
        gameId: 'crash_bandicoot',
        gameName: 'Crash Bandicoot',
        gameIcon: 'assets/games/crash_icon.png',
        characterImage: 'assets/characters/ryu_crash.png',
        engineName: 'Unreal Engine 4',
        description: 'Wumpa-powered hadoukens incoming.',
      ),
    ],
    portalPass: PortalPass(
      id: 'pp_ryu_s1',
      name: 'Season 1: The Wanderer',
      description:
          'Complete cross-game challenges to unlock legendary rewards.',
      currentLevel: 12,
      maxLevel: 50,
      progressPercent: 0.24,
      expiresAt: DateTime(2026, 6, 30),
      tasks: [
        PortalPassTask(
          id: 'task_ryu_1',
          title: 'Win 10 matches in Fortnite',
          targetGame: 'Fortnite',
          currentProgress: 7,
          targetProgress: 10,
          xpReward: 500,
        ),
        PortalPassTask(
          id: 'task_ryu_2',
          title: 'Complete 5 Roblox quests',
          targetGame: 'Roblox',
          currentProgress: 5,
          targetProgress: 5,
          xpReward: 300,
          isCompleted: true,
        ),
        PortalPassTask(
          id: 'task_ryu_3',
          title: 'Collect 100 island items',
          targetGame: 'Animal Crossing',
          currentProgress: 34,
          targetProgress: 100,
          xpReward: 750,
        ),
        PortalPassTask(
          id: 'task_ryu_4',
          title: 'Defeat 3 bosses',
          targetGame: 'Crash Bandicoot',
          currentProgress: 1,
          targetProgress: 3,
          xpReward: 1000,
        ),
      ],
      rewards: [
        PortalPassReward(
          id: 'rew_ryu_1',
          name: 'Golden Headband',
          image: 'assets/rewards/golden_headband.png',
          levelRequired: 10,
          isUnlocked: true,
        ),
        PortalPassReward(
          id: 'rew_ryu_2',
          name: 'Neon Gi',
          image: 'assets/rewards/neon_gi.png',
          levelRequired: 25,
        ),
        PortalPassReward(
          id: 'rew_ryu_3',
          name: 'Legendary Aura',
          image: 'assets/rewards/legendary_aura.png',
          levelRequired: 50,
        ),
      ],
    ),
    specialRewards: [
      SpecialReward(
        id: 'sr_hadouken',
        name: 'Hadouken',
        image: 'assets/rewards/hadouken.png',
        description: 'Iconic energy blast projectile.',
        isUnlocked: true,
        rarity: 'Epic',
      ),
      SpecialReward(
        id: 'sr_mask',
        name: 'Special Mask',
        image: 'assets/rewards/special_mask.png',
        description: 'Mysterious warrior mask from the ancient tournament.',
        rarity: 'Rare',
      ),
      SpecialReward(
        id: 'sr_scroll',
        name: 'Dragon Scroll',
        image: 'assets/rewards/dragon_scroll.png',
        description: 'Contains the secret of the Satsui no Hado.',
        rarity: 'Legendary',
      ),
    ],
    ownershipHistory: [
      PreviousOwner(
        username: '@shadow_dragon',
        ownedFrom: DateTime(2025, 8, 10),
        ownedUntil: DateTime(2025, 11, 3),
      ),
      PreviousOwner(
        username: '@pixel_samurai',
        ownedFrom: DateTime(2025, 11, 3),
        ownedUntil: DateTime(2026, 1, 15),
      ),
      PreviousOwner(
        username: '@jan_oer',
        ownedFrom: DateTime(2026, 1, 15),
        // ownedUntil: null = current owner
      ),
    ],
    gameplayMedia: [
      GameplayMedia(
        id: 'gp_ryu_1',
        imageUrl: 'assets/gameplay/ryu_fortnite_gameplay.png',
        caption: 'Hadouken meets the Battle Bus',
        gameName: 'Fortnite',
      ),
      GameplayMedia(
        id: 'gp_ryu_2',
        imageUrl: 'assets/gameplay/ryu_roblox_gameplay.png',
        caption: 'Training dojo experience',
        gameName: 'Roblox',
      ),
    ],
  ),

  // ─── VEGETA ───────────────────────────────────────────────
  OGACharacter(
    id: 'vegeta',
    name: 'Vegeta',
    ip: 'Dragon Ball Z',
    description:
        'The Prince of all Saiyans. Vegeta combines royal pride with '
        'devastating power, constantly pushing beyond his limits in '
        'pursuit of ultimate strength.',
    lore:
        'From the destruction of Planet Vegeta to his rivalry with Kakarot, '
        'Vegeta\'s journey from villain to protector is one of the most '
        'compelling arcs in anime history. His Final Flash and Galick Gun '
        'are feared across the multiverse.',
    heroImage: 'assets/characters/vegeta_hero.png',
    silhouetteImage: 'assets/characters/vegeta_silhouette.png',
    thumbnailImage: 'assets/characters/vegeta_thumb.png',
    rarity: 'Legendary',
    characterClass: 'Warrior',
    tags: ['anime', 'saiyan', 'dbz', 'toei'],
    isOwned: true,
    acquiredDate: DateTime(2026, 2, 1),
    progress: 0.45,
    gameVariations: [
      GameVariation(
        gameId: 'fortnite',
        gameName: 'Fortnite',
        gameIcon: 'assets/games/fortnite_icon.png',
        characterImage: 'assets/characters/vegeta_fortnite.png',
        engineName: 'Unreal Engine 5',
        description: 'The Saiyan Prince drops into the island.',
      ),
      GameVariation(
        gameId: 'roblox',
        gameName: 'Roblox',
        gameIcon: 'assets/games/roblox_icon.png',
        characterImage: 'assets/characters/vegeta_roblox.png',
        engineName: 'Roblox Engine',
        description: 'Over 9000 blocks of power.',
      ),
      GameVariation(
        gameId: 'animal_crossing',
        gameName: 'Animal Crossing',
        gameIcon: 'assets/games/animal_crossing_icon.png',
        characterImage: 'assets/characters/vegeta_animal_crossing.png',
        engineName: 'Nintendo Engine',
        description: 'Even the Prince needs a vacation island.',
      ),
    ],
    portalPass: PortalPass(
      id: 'pp_vegeta_s1',
      name: 'Season 1: Saiyan Pride',
      description: 'Prove your worth across the multiverse.',
      currentLevel: 8,
      maxLevel: 50,
      progressPercent: 0.16,
      tasks: [
        PortalPassTask(
          id: 'task_veg_1',
          title: 'Achieve 5 Victory Royales',
          targetGame: 'Fortnite',
          currentProgress: 2,
          targetProgress: 5,
          xpReward: 600,
        ),
        PortalPassTask(
          id: 'task_veg_2',
          title: 'Power level over 9000',
          targetGame: 'Roblox',
          currentProgress: 6500,
          targetProgress: 9000,
          xpReward: 900,
        ),
      ],
      rewards: [
        PortalPassReward(
          id: 'rew_veg_1',
          name: 'Saiyan Armor',
          image: 'assets/rewards/saiyan_armor.png',
          levelRequired: 5,
          isUnlocked: true,
        ),
        PortalPassReward(
          id: 'rew_veg_2',
          name: 'SSJ Blue Aura',
          image: 'assets/rewards/ssj_blue_aura.png',
          levelRequired: 30,
        ),
      ],
    ),
    specialRewards: [
      SpecialReward(
        id: 'sr_galick',
        name: 'Galick Gun',
        image: 'assets/rewards/galick_gun.png',
        description: 'Devastating energy wave attack.',
        isUnlocked: true,
        rarity: 'Epic',
      ),
      SpecialReward(
        id: 'sr_scouter',
        name: 'Royal Scouter',
        image: 'assets/rewards/royal_scouter.png',
        description: 'Vintage scouter from Planet Vegeta.',
        rarity: 'Legendary',
      ),
    ],
    ownershipHistory: [
      PreviousOwner(
        username: '@saiyan_elite',
        ownedFrom: DateTime(2025, 9, 20),
        ownedUntil: DateTime(2026, 2, 1),
      ),
      PreviousOwner(username: '@jan_oer', ownedFrom: DateTime(2026, 2, 1)),
    ],
    gameplayMedia: [
      GameplayMedia(
        id: 'gp_veg_1',
        imageUrl: 'assets/gameplay/vegeta_fortnite_gameplay.png',
        caption: 'Final Flash from the Storm Circle',
        gameName: 'Fortnite',
      ),
    ],
  ),

  // ─── GUGGIMON ─────────────────────────────────────────────
  OGACharacter(
    id: 'guggimon',
    name: 'Guggimon',
    ip: 'Superplastic',
    description:
        'The internet\'s most notorious fashion horror rabbit. '
        'Part streetwear icon, part nightmare fuel — Guggimon lives '
        'at the intersection of haute couture and digital chaos.',
    lore:
        'Created by Superplastic, Guggimon has transcended the vinyl toy '
        'world to become a cultural phenomenon. From Fortnite to virtual '
        'concerts, this masked menace redefines what a character can be '
        'across platforms.',
    heroImage: 'assets/characters/guggimon_hero.png',
    silhouetteImage: 'assets/characters/guggimon_silhouette.png',
    thumbnailImage: 'assets/characters/guggimon_thumb.png',
    rarity: 'Epic',
    characterClass: 'Trickster',
    tags: ['streetwear', 'horror', 'superplastic', 'fashion'],
    isOwned: false, // LOCKED — not owned
    progress: 0.0,
    gameVariations: [
      GameVariation(
        gameId: 'fortnite',
        gameName: 'Fortnite',
        gameIcon: 'assets/games/fortnite_icon.png',
        characterImage: 'assets/characters/guggimon_fortnite.png',
        engineName: 'Unreal Engine 5',
        description: 'Streetwear chaos drops into the island.',
      ),
      GameVariation(
        gameId: 'roblox',
        gameName: 'Roblox',
        gameIcon: 'assets/games/roblox_icon.png',
        characterImage: 'assets/characters/guggimon_roblox.png',
        engineName: 'Roblox Engine',
        description: 'Fashion horror in block form.',
      ),
    ],
    portalPass: null, // No pass attached — available for purchase
    specialRewards: [
      SpecialReward(
        id: 'sr_mask_gugg',
        name: 'Neon Skull Mask',
        image: 'assets/rewards/neon_skull_mask.png',
        description: 'Iconic horror-fashion headwear.',
        rarity: 'Epic',
      ),
      SpecialReward(
        id: 'sr_axe_gugg',
        name: 'Chaos Axe',
        image: 'assets/rewards/chaos_axe.png',
        description: 'Fashionably destructive.',
        rarity: 'Rare',
      ),
    ],
    ownershipHistory: [
      PreviousOwner(
        username: '@vinyl_collector',
        ownedFrom: DateTime(2025, 6, 1),
        ownedUntil: DateTime(2025, 12, 15),
      ),
      PreviousOwner(
        username: '@streetwear_king',
        ownedFrom: DateTime(2025, 12, 15),
      ),
    ],
    gameplayMedia: [
      GameplayMedia(
        id: 'gp_gugg_1',
        imageUrl: 'assets/gameplay/guggimon_fortnite_gameplay.png',
        caption: 'Fashion week meets fight night',
        gameName: 'Fortnite',
      ),
    ],
  ),
];

// ─── HELPER: Find character by ID ───────────────────────────
OGACharacter? findCharacterById(String id) {
  try {
    return hardcodedCharacters.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

// ─── HELPER: Get owned characters ───────────────────────────
List<OGACharacter> getOwnedCharacters() {
  return hardcodedCharacters.where((c) => c.isOwned).toList();
}

// ─── HELPER: Get all characters (owned first) ───────────────
List<OGACharacter> getAllCharactersSorted() {
  final owned = hardcodedCharacters.where((c) => c.isOwned).toList();
  final locked = hardcodedCharacters.where((c) => !c.isOwned).toList();
  return [...owned, ...locked];
}
