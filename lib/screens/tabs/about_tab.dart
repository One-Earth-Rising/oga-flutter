import 'package:flutter/material.dart';

/// About OGA Hub tab content.
/// Marketing/info page showing the OGA ecosystem overview.
class AboutTab extends StatefulWidget {
  const AboutTab({super.key});

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  final Set<int> _expandedFaqs = {};

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section
          _buildHeroSection(isMobile),
          const SizedBox(height: 48),

          // Description
          _buildDescriptionSection(isMobile),
          const SizedBox(height: 48),

          // All For Fans
          _buildAllForFansSection(isMobile),
          const SizedBox(height: 48),

          // Partner Logos
          _buildPartnerLogos(isMobile),
          const SizedBox(height: 48),

          // One Character, Infinite Worlds
          _buildInfiniteWorldsSection(isMobile),
          const SizedBox(height: 48),

          // Collect, Progress, Trade
          _buildCollectProgressTrade(isMobile),
          const SizedBox(height: 48),

          // FAQ
          _buildFaqSection(isMobile),
          const SizedBox(height: 48),

          // Footer
          _buildFooter(isMobile),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      height: isMobile ? 280 : 380,
      width: double.infinity,
      decoration: const BoxDecoration(color: neonGreen),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Characters collage (placeholder)
          Image.asset(
            'assets/heroes/hero.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: neonGreen,
              child: Center(
                child: Icon(
                  Icons.people,
                  color: Colors.black.withValues(alpha: 0.2),
                  size: 80,
                ),
              ),
            ),
          ),

          // Title overlay
          Positioned(
            left: isMobile ? 20 : 60,
            bottom: isMobile ? 20 : 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABOUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'OGA HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 36 : 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESCRIPTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildDescriptionSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: deepCharcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ironGrey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OGA icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: voidBlack,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.hexagon, color: Colors.white38, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'OGA Hub is the next cross-game character library where users can '
                  'collect, trade, and play with unique heroes across multiple supported '
                  'titles. Each character retains identity and progression, creating a '
                  'persistent legacy that evolves across platforms.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ALL FOR FANS
  // ═══════════════════════════════════════════════════════════

  Widget _buildAllForFansSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFansImage(),
                  const SizedBox(height: 24),
                  _buildFansText(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFansImage()),
                  const SizedBox(width: 40),
                  Expanded(child: _buildFansText()),
                ],
              ),
      ),
    );
  }

  Widget _buildFansImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: neonGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/heroes/hero.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.people,
              color: Colors.black.withValues(alpha: 0.3),
              size: 60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFansText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALL FOR\nFANS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create or purchase a unique OGA and take them across a growing '
          'universe of partnered games. From action RPGs to tactical shooters, '
          'your character\'s identity, levels, and backstory follow you — '
          'dynamically adapting to each game while preserving what makes '
          'your hero yours.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PARTNER LOGOS
  // ═══════════════════════════════════════════════════════════

  Widget _buildPartnerLogos(bool isMobile) {
    final partners = [
      'BLIZZARD',
      'EPIC',
      'ACTIVISION',
      'PLAYSTATION',
      'ACTIVISION',
      'ACTIVISION',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRUSTED BY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: partners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 32),
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    partners[index],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ONE CHARACTER, INFINITE WORLDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildInfiniteWorldsSection(bool isMobile) {
    return Container(
      height: isMobile ? 300 : 400,
      width: double.infinity,
      decoration: BoxDecoration(color: deepCharcoal),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B21A8).withValues(alpha: 0.3),
                  deepCharcoal,
                ],
              ),
            ),
          ),

          // Text overlay
          Positioned(
            left: isMobile ? 20 : 60,
            top: isMobile ? 20 : 40,
            right: isMobile ? 20 : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FORTNITE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: isMobile ? double.infinity : 300,
                  child: Text(
                    'Take your favorite characters into the world\'s most popular '
                    'battle royale. Your OGA character, your rules.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom title
          Positioned(
            left: isMobile ? 20 : 60,
            bottom: isMobile ? 20 : 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ONE CHARACTER,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    height: 1.0,
                  ),
                ),
                Text(
                  'INFINITE WORLDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COLLECT, PROGRESS, TRADE
  // ═══════════════════════════════════════════════════════════

  Widget _buildCollectProgressTrade(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: 48,
      ),
      color: neonGreen,
      child: Column(
        children: [
          Text(
            'IT\'S ALL ABOUT',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'COLLECT\nPROGRESS\nTRADE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 32),

          // Feature cards
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: isMobile
                ? Column(
                    children: [
                      _buildFeatureCard(
                        'PRESERVED GAMING VALUE',
                        'Keep what you\'ve earned and purchased.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        'CROSS-PLATFORM',
                        'Bring your favorite characters and items between games.',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          'PRESERVED GAMING VALUE',
                          'Keep what you\'ve earned and purchased.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFeatureCard(
                          'CROSS-PLATFORM',
                          'Bring your favorite characters and items between games.',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF004D00),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FAQ
  // ═══════════════════════════════════════════════════════════

  Widget _buildFaqSection(bool isMobile) {
    final faqs = [
      (
        'What is the OGA Hub?',
        'OGA Hub is a cross-game character platform that lets you own, trade, and play with unique characters across multiple supported titles.',
      ),
      (
        'How is this different from other gaming platforms?',
        'Unlike traditional platforms, OGA uses a patent-pending PNG container format that packages all game files for a character into a single ownable asset, ensuring true player ownership.',
      ),
      (
        'Do I need special knowledge or experience with technology?',
        'Not at all! OGA Hub is designed to be as simple as any gaming platform. Collect characters, play games, and trade with friends — the technology works seamlessly in the background.',
      ),
      (
        'Is the OGA Hub available now?',
        'OGA Hub is currently in early access. Sign up to be among the first to experience cross-game character ownership.',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            const Text(
              'FAQ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            ...faqs.asMap().entries.map(
              (e) => _buildFaqItem(e.key, e.value.$1, e.value.$2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index, String question, String answer) {
    final isExpanded = _expandedFaqs.contains(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedFaqs.remove(index);
          } else {
            _expandedFaqs.add(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ironGrey),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  answer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: 40,
      ),
      color: deepCharcoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation links
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children:
                [
                      'PORTAL PAGES',
                      'MY LIBRARY',
                      'MARKETPLACE',
                      'ACTIVITY',
                      'CONTACTS',
                      'ABOUT',
                    ]
                    .map(
                      (link) => Text(
                        link,
                        style: TextStyle(
                          color: neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),

          // Legal links
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children:
                [
                      'LEGAL',
                      'TERMS OF SERVICE',
                      'PRIVACY POLICY',
                      'COOKIE',
                      'LINK POLICY',
                    ]
                    .map(
                      (link) => Text(
                        link,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),

          // OGA Logo
          Image.asset(
            'assets/logo.png',
            height: 28,
            errorBuilder: (_, __, ___) => const Text(
              'OGA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© ogahub.com',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
