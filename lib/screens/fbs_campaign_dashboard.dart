import 'package:flutter/material.dart';
import 'dart:math' as math;

/// FBS Campaign Dashboard - Shows the 3 starter characters (Caustica, Bigwell, Brumblebutt)
/// Eventually merges with main dashboard bringing all collected assets over
class FBSCampaignDashboard extends StatefulWidget {
  final String? sessionId;
  final String? acquiredCharacterId;

  const FBSCampaignDashboard({
    super.key,
    this.sessionId,
    this.acquiredCharacterId,
  });

  @override
  State<FBSCampaignDashboard> createState() => _FBSCampaignDashboardState();
}

class _FBSCampaignDashboardState extends State<FBSCampaignDashboard> {
  static const Color ogaGreen = Color(0xFF00C806);
  static const Color ogaBlack = Color(0xFF000000);

  // FBS Starter Characters
  final List<FBSCharacter> _fbsCharacters = [
    FBSCharacter(
      id: 'caustica',
      name: 'CAUSTICA',
      subtitle: 'The Toxic Bee',
      imagePath:
          'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/caustica.png',
      glowColor: const Color(0xFFFFD700),
      rotation: -5.0,
    ),
    FBSCharacter(
      id: 'bigwell',
      name: 'BIGWELL',
      subtitle: 'The Gentle Giant',
      imagePath:
          'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/bigwell.png',
      glowColor: const Color(0xFF00FF00),
      rotation: 0.0,
    ),
    FBSCharacter(
      id: 'brumblebutt',
      name: 'BRUMBLEBUTT',
      subtitle: 'The Grumpy Bear',
      imagePath:
          'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/brumblebutt.png',
      glowColor: const Color(0xFFFF6B35),
      rotation: 5.0,
    ),
    FBSCharacter(
      id: 'melsh',
      name: 'MELSH',
      subtitle: 'Final Boss Sour',
      imagePath:
          'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/melsh.png',
      glowColor: const Color(0xFF00C8FF),
      rotation: -3.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: ogaBlack,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: ogaBlack,
            pinned: true,
            expandedHeight: 0,
            title: Center(
              child: Image.asset(
                'assets/logo.png',
                height: 28,
                errorBuilder: (_, __, ___) => const Text(
                  'OGA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.north_east, color: ogaGreen),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bolt, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Hero Section
          SliverToBoxAdapter(child: _buildHeroSection(isMobile)),

          // Characters Grid
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 60,
              vertical: 40,
            ),
            sliver: SliverToBoxAdapter(child: _buildCharacterCards(isMobile)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Stack(
      children: [
        // Hero Background
        Container(
          height: 400,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/heroes/hero.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                ogaBlack.withValues(alpha: 0.8),
                ogaBlack,
              ],
            ),
          ),
        ),

        // Profile Info
        Positioned(
          left: isMobile ? 20 : 60,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/characters/guggimon.png',
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 70,
                      width: 70,
                      color: ogaGreen,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Username
              const Text(
                'jan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '@jan',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 15),

              // Settings Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCards(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: 2 columns, Desktop: 4 columns (or 2 if narrow)
        final crossAxisCount = isMobile
            ? 2
            : (constraints.maxWidth > 1200 ? 4 : 2);
        final cardWidth =
            (constraints.maxWidth - ((crossAxisCount + 1) * 20)) /
            crossAxisCount;

        return Wrap(
          spacing: 20,
          runSpacing: 40,
          alignment: WrapAlignment.center,
          children: _fbsCharacters.map((character) {
            return _buildTiltedCard(character, cardWidth, isMobile);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTiltedCard(FBSCharacter character, double width, bool isMobile) {
    final bool isAcquired = character.id == widget.acquiredCharacterId;

    return Transform.rotate(
      angle: character.rotation * (math.pi / 180),
      child: Container(
        width: width,
        height: width * 1.3,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAcquired
                ? character.glowColor
                : Colors.white.withValues(alpha: 0.1),
            width: isAcquired ? 3 : 1,
          ),
          boxShadow: isAcquired
              ? [
                  BoxShadow(
                    color: character.glowColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Character Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  character.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: character.glowColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Character Name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isAcquired) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: character.glowColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACQUIRED',
                        style: TextStyle(
                          color: character.glowColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FBSCharacter {
  final String id;
  final String name;
  final String subtitle;
  final String imagePath;
  final Color glowColor;
  final double rotation; // Degrees for tilted cards

  FBSCharacter({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imagePath,
    required this.glowColor,
    required this.rotation,
  });
}
