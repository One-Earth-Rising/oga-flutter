// ═══════════════════════════════════════════════════════════════════
// OGA CHARACTER MODEL — Sprint 8B (Image Update)
// ═══════════════════════════════════════════════════════════════════
import 'dart:ui' show Color;
// All image paths are RELATIVE to Supabase Storage 'characters' bucket.
// Resolved to full URLs via OgaStorage.resolve() at render time.
// ═══════════════════════════════════════════════════════════════════

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
  final DateTime? acquiredDate;
  final double progress;

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

  String get imagePath => heroImage;

  Color get accentColor {
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

  /// Card background tint color (alias for accentColor)
  Color get cardColor => accentColor;

  static List<OGACharacter> get allCharacters => getAllCharactersSorted();
  static OGACharacter fromId(String? id) =>
      findCharacterById(id ?? 'ryu') ?? hardcodedCharacters.first;
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

// ═══════════════════════════════════════════════════════════════════
// HARDCODED MVP DATA — Storage-relative paths
// ═══════════════════════════════════════════════════════════════════

final List<OGACharacter> hardcodedCharacters = [
  // ─── RYU ──────────────────────────────────────────────────
  OGACharacter(
    id: 'ryu',
    name: 'Ryu',
    ip: 'Street Fighter',
    description:
        'A disciplined martial artist seeking true strength, Ryu is a master of Ansatsuken, blending powerful strikes, fluid movement, and precise technique.',
    lore:
        'His iconic Hadouken energy blast controls space, while the Shoryuken uppercut delivers crushing power. The Tatsumaki Senpukyaku spinning kick keeps opponents on edge. Balanced and adaptable, Ryu is perfect for players who value skill and mastery.',
    heroImage: 'heroes/ryu.png',
    silhouetteImage: 'silhouettes/ryu.png',
    thumbnailImage: 'thumbs/ryu.png',
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
        gameIcon: 'icons/fortnite.png',
        characterImage: 'games/ryu-fortnite.png',
        engineName: 'Unreal Engine 5',
        description: 'Battle Royale ready with signature gi and headband.',
      ),
      GameVariation(
        gameId: 'roblox',
        gameName: 'Roblox',
        gameIcon: 'icons/roblox.png',
        characterImage: 'games/ryu-roblox.png',
        engineName: 'Roblox Engine',
        description: 'Blocky martial arts master with classic moves.',
      ),
      GameVariation(
        gameId: 'animal_crossing',
        gameName: 'Animal Crossing',
        gameIcon: 'icons/animal-crossing.png',
        characterImage: 'games/ryu-animal-crossing.png',
        engineName: 'Nintendo Engine',
        description: 'Island life meets the World Warrior.',
      ),
      GameVariation(
        gameId: 'crash_bandicoot',
        gameName: 'Crash Bandicoot',
        gameIcon: 'icons/crash.png',
        characterImage: 'games/ryu-crash.png',
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
          image: 'pass-rewards/golden-headband.png',
          levelRequired: 10,
          isUnlocked: true,
        ),
        PortalPassReward(
          id: 'rew_ryu_2',
          name: 'Neon Gi',
          image: 'pass-rewards/neon-gi.png',
          levelRequired: 25,
        ),
        PortalPassReward(
          id: 'rew_ryu_3',
          name: 'Legendary Aura',
          image: 'pass-rewards/legendary-aura.png',
          levelRequired: 50,
        ),
      ],
    ),
    specialRewards: [
      SpecialReward(
        id: 'sr_hadouken',
        name: 'Hadouken',
        image: 'rewards/hadouken.png',
        description: 'Iconic energy blast projectile.',
        isUnlocked: true,
        rarity: 'Epic',
      ),
      SpecialReward(
        id: 'sr_mask',
        name: 'Special Mask',
        image: 'rewards/special-mask.png',
        description: 'Mysterious warrior mask from the ancient tournament.',
        rarity: 'Rare',
      ),
      SpecialReward(
        id: 'sr_scroll',
        name: 'Dragon Scroll',
        image: 'rewards/dragon-scroll.png',
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
      PreviousOwner(username: '@jan_oer', ownedFrom: DateTime(2026, 1, 15)),
    ],
    gameplayMedia: [
      GameplayMedia(
        id: 'gp_ryu_1',
        imageUrl: 'gameplay/ryu-fortnite.png',
        caption: 'Hadouken meets the Battle Bus',
        gameName: 'Fortnite',
      ),
      GameplayMedia(
        id: 'gp_ryu_2',
        imageUrl: 'gameplay/ryu-roblox.png',
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
        'The Prince of all Saiyans. Vegeta combines royal pride with devastating power, constantly pushing beyond his limits in pursuit of ultimate strength.',
    lore:
        'From the destruction of Planet Vegeta to his rivalry with Kakarot, Vegeta\'s journey from villain to protector is one of the most compelling arcs in anime history. His Final Flash and Galick Gun are feared across the multiverse.',
    heroImage: 'heroes/vegeta.png',
    silhouetteImage: 'silhouettes/vegeta.png',
    thumbnailImage: 'thumbs/vegeta.png',
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
        gameIcon: 'icons/fortnite.png',
        characterImage: 'games/vegeta-fortnite.png',
        engineName: 'Unreal Engine 5',
        description: 'The Saiyan Prince drops into the island.',
      ),
      GameVariation(
        gameId: 'roblox',
        gameName: 'Roblox',
        gameIcon: 'icons/roblox.png',
        characterImage: 'games/vegeta-roblox.png',
        engineName: 'Roblox Engine',
        description: 'Over 9000 blocks of power.',
      ),
      GameVariation(
        gameId: 'animal_crossing',
        gameName: 'Animal Crossing',
        gameIcon: 'icons/animal-crossing.png',
        characterImage: 'games/vegeta-animal-crossing.png',
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
          image: 'pass-rewards/saiyan-armor.png',
          levelRequired: 5,
          isUnlocked: true,
        ),
        PortalPassReward(
          id: 'rew_veg_2',
          name: 'SSJ Blue Aura',
          image: 'pass-rewards/ssj-blue-aura.png',
          levelRequired: 30,
        ),
      ],
    ),
    specialRewards: [
      SpecialReward(
        id: 'sr_galick',
        name: 'Galick Gun',
        image: 'rewards/galick-gun.png',
        description: 'Devastating energy wave attack.',
        isUnlocked: true,
        rarity: 'Epic',
      ),
      SpecialReward(
        id: 'sr_scouter',
        name: 'Royal Scouter',
        image: 'rewards/royal-scouter.png',
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
        imageUrl: 'gameplay/vegeta-fortnite.png',
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
        'The internet\'s most notorious fashion horror rabbit. Part streetwear icon, part nightmare fuel — Guggimon lives at the intersection of haute couture and digital chaos.',
    lore:
        'Created by Superplastic, Guggimon has transcended the vinyl toy world to become a cultural phenomenon. From Fortnite to virtual concerts, this masked menace redefines what a character can be across platforms.',
    heroImage: 'heroes/guggimon.png',
    silhouetteImage: 'silhouettes/guggimon.png',
    thumbnailImage: 'thumbs/guggimon.png',
    rarity: 'Epic',
    characterClass: 'Trickster',
    tags: ['streetwear', 'horror', 'superplastic', 'fashion'],
    isOwned: false,
    progress: 0.0,
    gameVariations: [
      GameVariation(
        gameId: 'fortnite',
        gameName: 'Fortnite',
        gameIcon: 'icons/fortnite.png',
        characterImage: 'games/guggimon-fortnite.png',
        engineName: 'Unreal Engine 5',
        description: 'Streetwear chaos drops into the island.',
      ),
      GameVariation(
        gameId: 'roblox',
        gameName: 'Roblox',
        gameIcon: 'icons/roblox.png',
        characterImage: 'games/guggimon-roblox.png',
        engineName: 'Roblox Engine',
        description: 'Fashion horror in block form.',
      ),
    ],
    portalPass: null,
    specialRewards: [
      SpecialReward(
        id: 'sr_mask_gugg',
        name: 'Neon Skull Mask',
        image: 'rewards/neon-skull-mask.png',
        description: 'Iconic horror-fashion headwear.',
        rarity: 'Epic',
      ),
      SpecialReward(
        id: 'sr_axe_gugg',
        name: 'Chaos Axe',
        image: 'rewards/chaos-axe.png',
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
        imageUrl: 'gameplay/guggimon-fortnite.png',
        caption: 'Fashion week meets fight night',
        gameName: 'Fortnite',
      ),
    ],
  ),
];

OGACharacter? findCharacterById(String id) {
  try {
    return hardcodedCharacters.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

List<OGACharacter> getOwnedCharacters() =>
    hardcodedCharacters.where((c) => c.isOwned).toList();
List<OGACharacter> getAllCharactersSorted() {
  final owned = hardcodedCharacters.where((c) => c.isOwned).toList();
  final locked = hardcodedCharacters.where((c) => !c.isOwned).toList();
  return [...owned, ...locked];
}
