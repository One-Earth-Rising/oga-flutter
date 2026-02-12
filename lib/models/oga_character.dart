import 'package:flutter/material.dart';

// ─── GAME INFO ──────────────────────────────────────────────

/// Represents a game that a character is available in
class GameInfo {
  final String id;
  final String name;
  final String iconPath;
  final String? logoPath; // Large game logo for detail view

  const GameInfo({
    required this.id,
    required this.name,
    required this.iconPath,
    this.logoPath,
  });

  static const fortnite = GameInfo(
    id: 'fortnite',
    name: 'Fortnite',
    iconPath: 'assets/games/fortnite.png',
    logoPath: 'assets/games/fortnite_logo.png',
  );
  static const streetFighter = GameInfo(
    id: 'street_fighter',
    name: 'Street Fighter 6',
    iconPath: 'assets/games/street_fighter.png',
    logoPath: 'assets/games/street_fighter_logo.png',
  );
  static const dbz = GameInfo(
    id: 'dbz',
    name: 'Dragon Ball Z: Kakarot',
    iconPath: 'assets/games/dbz.png',
    logoPath: 'assets/games/dbz_logo.png',
  );
  static const roblox = GameInfo(
    id: 'roblox',
    name: 'Roblox',
    iconPath: 'assets/games/roblox.png',
    logoPath: 'assets/games/roblox_logo.png',
  );
  static const r6siege = GameInfo(
    id: 'r6siege',
    name: 'Rainbow Six Siege',
    iconPath: 'assets/games/r6siege.png',
    logoPath: 'assets/games/r6siege_logo.png',
  );
  static const overwatch = GameInfo(
    id: 'overwatch',
    name: 'Overwatch 2',
    iconPath: 'assets/games/overwatch.png',
    logoPath: 'assets/games/overwatch_logo.png',
  );
}

// ─── GAME VARIATION ─────────────────────────────────────────

/// A specific version of a character as it appears in a particular game.
/// Each OGA container holds multiple game-specific renders.
class GameVariation {
  final GameInfo game;
  final String variationImagePath; // Full render for this game version
  final String? variantName; // e.g. "Super Saiyan God SS Evolved"

  const GameVariation({
    required this.game,
    required this.variationImagePath,
    this.variantName,
  });
}

// ─── PORTAL PASS ────────────────────────────────────────────

/// A task within a Portal Pass attached to a character
class PortalPassTask {
  final int index;
  final String title;
  final String? iconPath;
  final int current;
  final int total;

  const PortalPassTask({
    required this.index,
    required this.title,
    this.iconPath,
    this.current = 0,
    this.total = 1,
  });

  bool get isComplete => current >= total;
  String get progressLabel => '$current/$total';
}

/// Portal Pass progress for a character
class PortalPass {
  final double progress; // 0.0 - 1.0
  final List<PortalPassTask> tasks;

  const PortalPass({required this.progress, required this.tasks});

  int get completedCount => tasks.where((t) => t.isComplete).length;
  String get percentLabel => '${(progress * 100).toInt()}%';
}

// ─── OWNERSHIP ──────────────────────────────────────────────

/// Represents someone who owns a copy of this OGA
class OwnerRecord {
  final String displayName;
  final String handle;
  final String? avatarPath;
  final String? value; // e.g. "120€"

  const OwnerRecord({
    required this.displayName,
    required this.handle,
    this.avatarPath,
    this.value,
  });
}

// ─── RARITY ─────────────────────────────────────────────────

enum CharacterRarity {
  common,
  rare,
  epic,
  legendary;

  String get label => name.toUpperCase();

  Color get color {
    switch (this) {
      case CharacterRarity.common:
        return const Color(0xFF888888);
      case CharacterRarity.rare:
        return const Color(0xFF3B82F6);
      case CharacterRarity.epic:
        return const Color(0xFFA855F7);
      case CharacterRarity.legendary:
        return const Color(0xFFF59E0B);
    }
  }
}

// ─── CORE CHARACTER MODEL ───────────────────────────────────

/// The OGA (Ownable Game Asset) container.
/// Contains all data needed to display a character across games.
/// Designed to be populated from a centralized backend.
class OGACharacter {
  final String id;
  final String name;
  final String subtitle; // Variant name, e.g. "Super Saiyan God SS Evolved"
  final String ip; // Intellectual property franchise
  final String description;
  final String imagePath; // Primary card image
  final Color cardColor; // IP-specific background tint
  final Color glowColor; // Glow effect color
  final CharacterRarity rarity;
  final List<String> traits;

  // Game-specific data (populated from OGA container)
  final List<GameVariation> gameVariations;

  // Portal Pass (optional, attached per-character)
  final PortalPass? portalPass;

  // Ownership data (populated from backend)
  final List<OwnerRecord> owners;

  const OGACharacter({
    required this.id,
    required this.name,
    this.subtitle = '',
    required this.ip,
    required this.description,
    required this.imagePath,
    required this.cardColor,
    required this.glowColor,
    required this.rarity,
    this.traits = const [],
    this.gameVariations = const [],
    this.portalPass,
    this.owners = const [],
  });

  /// Convenience: list of games this character is in
  List<GameInfo> get availableGames =>
      gameVariations.map((v) => v.game).toList();

  // ─── CHARACTER ROSTER ───────────────────────────────────

  static const ryu = OGACharacter(
    id: 'ryu',
    name: 'RYU',
    subtitle: 'THE ETERNAL WARRIOR',
    ip: 'Street Fighter',
    description:
        'A disciplined martial artist seeking true strength. Ryu is a master '
        'of Ansatsuken, blending powerful strikes, fluid movement, and precise '
        'technique. His iconic Hadouken energy blast controls space, while the '
        'Tatsumaki Senpukyaku spinning kick keeps opponents on edge. Balanced '
        'and adaptable, Ryu is perfect for players who value skill and mastery.',
    imagePath: 'assets/characters/ryu.png',
    cardColor: Color(0xFFDC2626),
    glowColor: Color(0xFFEF4444),
    rarity: CharacterRarity.legendary,
    traits: ['Disciplined', 'Powerful', 'Balanced'],
    gameVariations: [
      GameVariation(
        game: GameInfo.streetFighter,
        variationImagePath: 'assets/characters/ryu.png',
        variantName: 'Classic',
      ),
      GameVariation(
        game: GameInfo.fortnite,
        variationImagePath: 'assets/characters/ryu.png',
        variantName: 'Fortnite Edition',
      ),
    ],
    portalPass: PortalPass(
      progress: 0.60,
      tasks: [
        PortalPassTask(index: 1, title: 'Scan at Area15', current: 1, total: 1),
        PortalPassTask(
          index: 2,
          title: 'Watch Street Fighter 6 Trailer',
          current: 1,
          total: 1,
        ),
        PortalPassTask(
          index: 3,
          title: 'Complete OGA Profile',
          current: 1,
          total: 1,
        ),
        PortalPassTask(
          index: 4,
          title: 'Share Character on Social',
          current: 0,
          total: 1,
        ),
        PortalPassTask(
          index: 5,
          title: 'Play in Fortnite',
          current: 0,
          total: 1,
        ),
      ],
    ),
    owners: [
      OwnerRecord(
        displayName: 'NIGHT KNIGHT',
        handle: '@nknight',
        value: '150€',
      ),
      OwnerRecord(displayName: 'RYUMAIN99', handle: '@ryumain', value: '120€'),
    ],
  );

  static const vegeta = OGACharacter(
    id: 'vegeta',
    name: 'VEGETA',
    subtitle: 'SUPER SAIYAN GOD SS EVOLVED',
    ip: 'Dragon Ball Z',
    description:
        'Vegeta is the proud prince of the Saiyan race in Dragon Ball. '
        'Initially a ruthless villain, he evolves into a powerful warrior and '
        'protector of Earth. Driven by his rivalry with Goku, he constantly '
        'pushes his limits, mastering transformations like Super Saiyan and '
        'Ultra Ego. Despite his arrogance, he deeply cares for his family.',
    imagePath: 'assets/characters/vegeta.png',
    cardColor: Color(0xFF2563EB),
    glowColor: Color(0xFF3B82F6),
    rarity: CharacterRarity.legendary,
    traits: ['Proud', 'Relentless', 'Tactical'],
    gameVariations: [
      GameVariation(
        game: GameInfo.fortnite,
        variationImagePath: 'assets/characters/vegeta.png',
        variantName: 'Fortnite Edition',
      ),
      GameVariation(
        game: GameInfo.overwatch,
        variationImagePath: 'assets/characters/vegeta.png',
        variantName: 'Overwatch Edition',
      ),
      GameVariation(
        game: GameInfo.dbz,
        variationImagePath: 'assets/characters/vegeta.png',
        variantName: 'Classic',
      ),
    ],
    portalPass: PortalPass(
      progress: 0.75,
      tasks: [
        PortalPassTask(index: 1, title: 'Scan at Area15', current: 1, total: 1),
        PortalPassTask(
          index: 2,
          title: 'Watch New Fortnite Trailer',
          current: 1,
          total: 1,
        ),
        PortalPassTask(
          index: 3,
          title: 'Watch New Fortnite Trailer',
          current: 1,
          total: 1,
        ),
        PortalPassTask(
          index: 4,
          title: 'Watch New Fortnite Trailer',
          current: 0,
          total: 1,
        ),
        PortalPassTask(
          index: 5,
          title: 'Watch New Fortnite Trailer',
          current: 0,
          total: 1,
        ),
      ],
    ),
    owners: [
      OwnerRecord(
        displayName: 'NIGHT KNIGHT',
        handle: '@nknight',
        value: '120€',
      ),
      OwnerRecord(displayName: 'BISKIT', handle: '@BISKIT', value: '96€'),
      OwnerRecord(displayName: 'OVERLY-OVER', handle: '@O-O', value: '90€'),
    ],
  );

  static const guggimon = OGACharacter(
    id: 'guggimon',
    name: 'GUGGIMON',
    subtitle: 'FASHION HORROR ICON',
    ip: 'Superplastic',
    description:
        'The internet\'s most notorious fashion horror rabbit. Guggimon is a '
        'cultural icon bridging designer toys, fashion, and gaming. With '
        'appearances across multiple metaverses and collaborations with top '
        'brands, Guggimon represents the new wave of IP that lives natively '
        'across digital worlds.',
    imagePath: 'assets/characters/guggimon.png',
    cardColor: Color(0xFF7C3AED),
    glowColor: Color(0xFFA855F7),
    rarity: CharacterRarity.epic,
    traits: ['Notorious', 'Iconic', 'Versatile'],
    gameVariations: [
      GameVariation(
        game: GameInfo.fortnite,
        variationImagePath: 'assets/characters/guggimon.png',
        variantName: 'Fortnite Edition',
      ),
      GameVariation(
        game: GameInfo.roblox,
        variationImagePath: 'assets/characters/guggimon.png',
        variantName: 'Roblox Edition',
      ),
      GameVariation(
        game: GameInfo.r6siege,
        variationImagePath: 'assets/characters/guggimon.png',
        variantName: 'Siege Edition',
      ),
    ],
    portalPass: PortalPass(
      progress: 0.40,
      tasks: [
        PortalPassTask(
          index: 1,
          title: 'Complete OGA Profile',
          current: 1,
          total: 1,
        ),
        PortalPassTask(
          index: 2,
          title: 'Share on Social Media',
          current: 1,
          total: 1,
        ),
        PortalPassTask(index: 3, title: 'Play in Roblox', current: 0, total: 1),
        PortalPassTask(
          index: 4,
          title: 'Collect 3 Rewards',
          current: 0,
          total: 3,
        ),
        PortalPassTask(
          index: 5,
          title: 'Trade with a Friend',
          current: 0,
          total: 1,
        ),
      ],
    ),
    owners: [
      OwnerRecord(displayName: 'GUGGIFAN', handle: '@guggifan', value: '80€'),
      OwnerRecord(displayName: 'PLASTIK', handle: '@plastik', value: '72€'),
    ],
  );

  static const List<OGACharacter> allCharacters = [ryu, vegeta, guggimon];

  /// Lookup character by ID with fallback
  static OGACharacter fromId(String? id) {
    return allCharacters.firstWhere((c) => c.id == id, orElse: () => ryu);
  }
}
