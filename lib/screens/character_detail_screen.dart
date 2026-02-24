// ═══════════════════════════════════════════════════════════════════
// CHARACTER DETAIL SCREEN — Sprint 8B
// ═══════════════════════════════════════════════════════════════════
// Full Figma-matching detail view with:
//   • Dramatic hero section with title overlay
//   • Character description & lore
//   • Game Variations (Multigameverse) horizontal carousel
//   • Portal Pass progress + tasks
//   • Special Rewards carousel
//   • Ownership History chain
//   • Gameplay Media gallery
//   • CHARACTER LOCKED state for unowned assets
//
// Layout:
//   Desktop (>900px): Split pane — hero left, info right
//   Mobile (<900px): Full-bleed hero scrolling into content
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../models/oga_character.dart';
import '../widgets/oga_image.dart';

// ─── Brand Colors (Heimdal V2) ──────────────────────────────
const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);

class CharacterDetailScreen extends StatefulWidget {
  final OGACharacter character;
  final bool isOwned;

  const CharacterDetailScreen({
    super.key,
    required this.character,
    this.isOwned = false,
  });

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen>
    with SingleTickerProviderStateMixin {
  // Currently selected game variation (for hero image swap)
  int _selectedVariationIndex = -1; // -1 = default hero
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late PageController _heroPageController;

  OGACharacter get ch => widget.character;
  bool get owned => widget.isOwned;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _heroPageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String get _currentGameLabel {
    if (_selectedVariationIndex >= 0 &&
        _selectedVariationIndex < ch.gameVariations.length) {
      return ch.gameVariations[_selectedVariationIndex].gameName.toUpperCase();
    }
    return 'ORIGINAL';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _voidBlack,
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Split Pane
  // ═══════════════════════════════════════════════════════════

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Hero image (sticky)
        Expanded(flex: 5, child: _buildHeroSection(isDesktop: true)),
        // Right: Scrollable content
        Expanded(flex: 5, child: _buildContentPanel()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT — Full-bleed scroll
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        // Hero as sliver app bar
        SliverAppBar(
          expandedHeight: 420,
          pinned: true,
          backgroundColor: _voidBlack,
          leading: _buildBackButton(),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroSection(isDesktop: false),
          ),
        ),
        // Content
        SliverToBoxAdapter(child: _buildAllSections()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroSection({required bool isDesktop}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: silhouette or gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _voidBlack,
                _getRarityColor().withValues(alpha: 0.15),
                _voidBlack,
              ],
            ),
          ),
        ),

        // Character image with animated glow
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Center(
              child: Container(
                decoration: owned
                    ? BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: _neonGreen.withValues(
                              alpha: _glowAnimation.value * 0.3,
                            ),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      )
                    : null,
                child: _buildHeroPageView(),
              ),
            );
          },
        ),

        // Gradient overlay at bottom for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, _voidBlack.withValues(alpha: 0.9)],
              ),
            ),
          ),
        ),

        // Title overlay
        Positioned(
          bottom: isDesktop ? 40 : 20,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game label badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _neonGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _currentGameLabel,
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Character name
              Text(
                ch.name.toUpperCase(),
                style: const TextStyle(
                  color: _pureWhite,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                'THE ${ch.characterClass.toUpperCase()}',
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              // Rarity + IP badge row
              Row(
                children: [
                  _buildBadge(ch.rarity.toUpperCase(), _getRarityColor()),
                  const SizedBox(width: 8),
                  _buildBadge(ch.ip.toUpperCase(), _ironGrey),
                  if (owned) ...[
                    const SizedBox(width: 8),
                    _buildBadge('OWNED', _neonGreen),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Back button (desktop only — mobile uses SliverAppBar)
        if (isDesktop) Positioned(top: 16, left: 16, child: _buildBackButton()),
      ],
    );
  }

  Widget _buildHeroPageView() {
    // Pages: [original hero, variation 0, variation 1, ...]
    final totalPages = 1 + ch.gameVariations.length;

    return Container(
      width: 280,
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _deepCharcoal,
        border: Border.all(
          color: owned ? _neonGreen.withValues(alpha: 0.3) : _ironGrey,
          width: owned ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Swipeable hero images
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: PageView.builder(
              controller: _heroPageController,
              itemCount: totalPages,
              onPageChanged: (page) {
                setState(() {
                  // Page 0 = original (-1), page 1+ = variation index
                  _selectedVariationIndex = page - 1;
                });
              },
              itemBuilder: (context, page) {
                final imagePath = page == 0
                    ? ch.heroImage
                    : ch.gameVariations[page - 1].characterImage;

                return OgaImage(
                  path: imagePath,
                  fit: BoxFit.cover,
                  accentColor: _getRarityColor(),
                  fallbackIcon: Icons.person,
                  fallbackIconSize: 64,
                );
              },
            ),
          ),

          // Lock overlay for unowned
          if (!owned)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: _voidBlack.withValues(alpha: 0.6),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: _pureWhite.withValues(alpha: 0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LOCKED',
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Page indicator dots
          if (totalPages > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) {
                  final isActive = i == (_selectedVariationIndex + 1);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _neonGreen
                          : _pureWhite.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          // Swipe hint arrows (left/right)
          if (ch.gameVariations.isNotEmpty) ...[
            // Left arrow (when not on first page)
            if (_selectedVariationIndex >= 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _heroPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _voidBlack.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: _pureWhite.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            // Right arrow (when not on last page)
            if (_selectedVariationIndex < ch.gameVariations.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _heroPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _voidBlack.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: _pureWhite.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENT PANEL (right side on desktop, below hero on mobile)
  // ═══════════════════════════════════════════════════════════

  Widget _buildContentPanel() {
    return Column(
      children: [
        // Back button row for desktop
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              _buildBackButton(),
              const Spacer(),
              if (owned) _buildShareButton(),
            ],
          ),
        ),
        Expanded(child: _buildAllSections()),
      ],
    );
  }

  Widget _buildAllSections() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CHARACTER LOCKED CTA (unowned) ──────────────
          if (!owned) _buildLockedCTA(),

          // ── ABOUT ──────────────────────────────────────
          _buildSectionCard(
            title: 'ABOUT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.description,
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                if (ch.lore.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    ch.lore,
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── MULTIGAMEVERSE ─────────────────────────────
          _buildSectionCard(
            title: '${ch.name.toUpperCase()} MULTIGAMEVERSE',
            subtitle: '${ch.gameVariations.length} GAMES',
            child: _buildGameVariations(),
            locked: !owned,
            lockedMessage: 'Own this character to explore all game versions',
          ),
          const SizedBox(height: 20),

          // ── PORTAL PASS ────────────────────────────────
          _buildPortalPassSection(),
          const SizedBox(height: 20),

          // ── SPECIAL REWARDS ────────────────────────────
          _buildSectionCard(
            title: 'SPECIAL REWARDS',
            subtitle: '${ch.specialRewards.length} ITEMS',
            child: _buildSpecialRewards(),
            locked: !owned,
            lockedMessage: 'Own this character to unlock rewards',
          ),
          const SizedBox(height: 20),

          // ── OWNERSHIP HISTORY ──────────────────────────
          _buildSectionCard(
            title: 'OWNERSHIP HISTORY',
            subtitle: '${ch.ownershipHistory.length} OWNERS',
            child: _buildOwnershipHistory(),
          ),
          const SizedBox(height: 20),

          // ── GAMEPLAY ───────────────────────────────────
          if (ch.gameplayMedia.isNotEmpty)
            _buildSectionCard(
              title: 'GAMEPLAY',
              child: _buildGameplayGallery(),
              locked: !owned,
              lockedMessage: 'Own this character to view gameplay',
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CHARACTER LOCKED CTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildLockedCTA() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_neonGreen.withValues(alpha: 0.08), _deepCharcoal],
        ),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: _neonGreen, size: 32),
          const SizedBox(height: 12),
          const Text(
            'CHARACTER LOCKED',
            style: TextStyle(
              color: _neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acquire this OGA to unlock the full experience — '
            'game variations, Portal Pass, rewards, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to marketplace / acquisition flow
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: _voidBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'GET THIS CHARACTER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to Portal Pass purchase
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _pureWhite,
                  side: const BorderSide(color: _ironGrey),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'VIEW PASS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION CARD WRAPPER
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
    bool locked = false,
    String lockedMessage = '',
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: _neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content — with optional lock overlay
          if (locked)
            _buildLockedOverlay(child, lockedMessage)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildLockedOverlay(Widget child, String message) {
    return Stack(
      children: [
        // Blurred/dimmed content preview
        Opacity(
          opacity: 0.25,
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
          ),
        ),
        // Lock overlay
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: _pureWhite.withValues(alpha: 0.4),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _neonGreen.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SIGN UP TO UNLOCK',
                    style: TextStyle(
                      color: _neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GAME VARIATIONS (MULTIGAMEVERSE) — Sprint 9A: Tap-to-Expand
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameVariations() {
    if (ch.gameVariations.isEmpty) {
      return Text(
        'No game variations available yet.',
        style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Horizontal Carousel ─────────────────────────
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ch.gameVariations.length,
            itemBuilder: (context, index) {
              final variation = ch.gameVariations[index];
              final isSelected = _selectedVariationIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariationIndex = isSelected ? -1 : index;
                  });
                  // Sync hero PageView: index -1 = page 0, index N = page N+1
                  final targetPage = isSelected ? 0 : index + 1;
                  if (_heroPageController.hasClients) {
                    _heroPageController.animateToPage(
                      targetPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 140,
                  margin: EdgeInsets.only(
                    right: index < ch.gameVariations.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _voidBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _neonGreen
                          : _ironGrey.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _neonGreen.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game variation image
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: OgaImage(
                                path: variation.characterImage,
                                fit: BoxFit.cover,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                                accentColor: _getRarityColor(),
                                fallbackIcon: Icons.videogame_asset,
                                fallbackIconSize: 32,
                              ),
                            ),
                            // Selected indicator arrow
                            if (isSelected)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: _neonGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.expand_more,
                                    color: _voidBlack,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Game info
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _neonGreen.withValues(alpha: 0.05)
                              : _deepCharcoal,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(11),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Game icon
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: variation.gameIcon.isNotEmpty
                                      ? OgaImage(
                                          path: variation.gameIcon,
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.sports_esports,
                                          fallbackIconSize: 10,
                                        )
                                      : Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _ironGrey,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.sports_esports,
                                            size: 10,
                                            color: _pureWhite.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    variation.gameName.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? _neonGreen
                                          : _pureWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              variation.description,
                              style: TextStyle(
                                color: _pureWhite.withValues(alpha: 0.4),
                                fontSize: 9,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Expanded Detail Panel ───────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              _selectedVariationIndex >= 0 &&
                  _selectedVariationIndex < ch.gameVariations.length
              ? _buildExpandedVariationDetail(
                  ch.gameVariations[_selectedVariationIndex],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Expanded detail panel for the selected game variation.
  /// Shows below the carousel with a slide-in animation.
  Widget _buildExpandedVariationDetail(GameVariation variation) {
    return Container(
      key: ValueKey('variation_${variation.gameId}'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voidBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: _neonGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: game name + engine badge + close ──
          Row(
            children: [
              // Game icon
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: variation.gameIcon.isNotEmpty
                    ? OgaImage(
                        path: variation.gameIcon,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.sports_esports,
                        fallbackIconSize: 14,
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _ironGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.sports_esports,
                          size: 14,
                          color: _pureWhite.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Game name
              Expanded(
                child: Text(
                  variation.gameName.toUpperCase(),
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Engine badge
              if (variation.engineName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _deepCharcoal,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    variation.engineName.toUpperCase(),
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Close button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariationIndex = -1;
                  });
                  if (_heroPageController.hasClients) {
                    _heroPageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _ironGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close,
                    color: _pureWhite.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Character render + info ─────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              // Side-by-side on wider panels, stacked on narrow
              final isWide = constraints.maxWidth > 360;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Character image
                    _buildVariationRender(variation),
                    const SizedBox(width: 16),
                    // Info column
                    Expanded(child: _buildVariationInfo(variation)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildVariationRender(variation)),
                    const SizedBox(height: 14),
                    _buildVariationInfo(variation),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Large render of the character in this game variation.
  Widget _buildVariationRender(GameVariation variation) {
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _deepCharcoal,
        border: Border.all(color: _neonGreen.withValues(alpha: 0.15), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: OgaImage(
              path: variation.characterImage,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(11),
              accentColor: _getRarityColor(),
              fallbackIcon: Icons.videogame_asset,
              fallbackIconSize: 48,
            ),
          ),
          // Game ID badge at top-left
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _voidBlack.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variation.gameName.toUpperCase(),
                style: const TextStyle(
                  color: _neonGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Text info panel for the expanded variation.
  Widget _buildVariationInfo(GameVariation variation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character name in this game
        Text(
          '${ch.name.toUpperCase()} IN ${variation.gameName.toUpperCase()}',
          style: TextStyle(
            color: _neonGreen,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),

        // Description
        if (variation.description.isNotEmpty)
          Text(
            variation.description,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 14),

        // Engine + platform info row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (variation.engineName.isNotEmpty)
              _buildInfoChip(Icons.memory, variation.engineName),
            _buildInfoChip(Icons.videogame_asset, variation.gameName),
            _buildInfoChip(Icons.category, ch.ip),
          ],
        ),
        const SizedBox(height: 16),

        // "VIEW IN GAME" CTA (placeholder for future deep-link)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Deep-link to this game variation or show more info
            },
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text(
              'VIEW IN GAME',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 11,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _neonGreen,
              side: BorderSide(color: _neonGreen.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Small info chip for engine/platform details.
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _pureWhite.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PORTAL PASS SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildPortalPassSection() {
    final pass = ch.portalPass;

    if (pass == null) {
      // No Portal Pass — show purchase CTA (unchanged)
      return _buildSectionCard(
        title: 'PORTAL PASS',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _ironGrey, width: 1),
          ),
          child: Column(
            children: [
              Icon(
                Icons.rocket_launch,
                color: _neonGreen.withValues(alpha: 0.5),
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'NO PORTAL PASS ATTACHED',
                style: TextStyle(
                  color: _pureWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock cross-game challenges and exclusive rewards.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _neonGreen,
                    side: BorderSide(color: _neonGreen.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'BROWSE PORTAL PASSES',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has Portal Pass — interactive version
    return _buildSectionCard(
      title: 'PORTAL PASS',
      subtitle: 'LVL ${pass.currentLevel}/${pass.maxLevel}',
      locked: !owned,
      lockedMessage: 'Own this character to track Portal Pass progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pass name + description
          Text(
            pass.name.toUpperCase(),
            style: const TextStyle(
              color: _neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          if (pass.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pass.description,
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Progress bar
          _buildProgressBar(
            pass.progressPercent,
            pass.currentLevel,
            pass.maxLevel,
          ),
          const SizedBox(height: 20),

          // Expiry
          if (pass.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: _pureWhite.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expires: ${_formatDate(pass.expiresAt!)}',
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

          // ── Reward Milestones (interactive nodes) ──────
          if (pass.rewards.isNotEmpty) ...[
            Text(
              'MILESTONE REWARDS',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildMilestoneTrack(pass),
            const SizedBox(height: 20),
          ],

          // ── Active Tasks (expandable) ─────────────────
          if (pass.tasks.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'ACTIVE TASKS',
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${pass.tasks.where((t) => t.isCompleted).length}/${pass.tasks.length}',
                    style: TextStyle(
                      color: _neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...pass.tasks.map((task) => _buildInteractiveTaskItem(task)),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(double percent, int current, int max) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LEVEL $current',
              style: const TextStyle(
                color: _neonGreen,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: _ironGrey,
            valueColor: const AlwaysStoppedAnimation(_neonGreen),
          ),
        ),
      ],
    );
  }

  /// Horizontal milestone track with nodes connected by a progress line.
  Widget _buildMilestoneTrack(PortalPass pass) {
    return SizedBox(
      height: 100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final nodeCount = pass.rewards.length;
          if (nodeCount == 0) return const SizedBox.shrink();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Layer 1: Background track line
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _ironGrey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Layer 2: Progress fill line (behind nodes)
              Positioned(
                top: 24,
                left: 0,
                child: Container(
                  height: 3,
                  width: trackWidth * pass.progressPercent,
                  decoration: BoxDecoration(
                    color: _neonGreen,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: _neonGreen.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              // Layer 3: Milestone nodes (on top of everything)
              ...List.generate(nodeCount, (index) {
                final reward = pass.rewards[index];
                final position = nodeCount == 1
                    ? trackWidth / 2
                    : (trackWidth - 40) * (index / (nodeCount - 1)) + 20;
                final nodeLevel = reward.levelRequired;
                final isReached = pass.currentLevel >= nodeLevel;

                return Positioned(
                  left: position - 20,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => _showRewardDetail(context, reward, isReached),
                    child: SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          // Level label
                          Text(
                            'LVL $nodeLevel',
                            style: TextStyle(
                              color: isReached
                                  ? _neonGreen
                                  : _pureWhite.withValues(alpha: 0.3),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Node circle — solid background so line doesn't show through
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Solid background to mask the progress line
                              color: isReached
                                  ? const Color(0xFF1A3A14)
                                  : _deepCharcoal,
                              border: Border.all(
                                color: isReached
                                    ? _neonGreen
                                    : _ironGrey.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: isReached
                                  ? [
                                      BoxShadow(
                                        color: _neonGreen.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isReached
                                  ? const Icon(
                                      Icons.check,
                                      color: _neonGreen,
                                      size: 14,
                                    )
                                  : Icon(
                                      Icons.lock_outline,
                                      color: _ironGrey.withValues(alpha: 0.6),
                                      size: 12,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Reward name
                          Text(
                            reward.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isReached
                                  ? _pureWhite.withValues(alpha: 0.8)
                                  : _pureWhite.withValues(alpha: 0.3),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// Shows a bottom sheet with reward details when a milestone node is tapped.
  void _showRewardDetail(
    BuildContext context,
    PortalPassReward reward,
    bool isUnlocked,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _deepCharcoal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isUnlocked ? _neonGreen.withValues(alpha: 0.3) : _ironGrey,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _ironGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Reward image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _neonGreen.withValues(alpha: 0.1)
                      : _voidBlack,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked
                        ? _neonGreen.withValues(alpha: 0.4)
                        : _ironGrey,
                  ),
                ),
                child: OgaImage(
                  path: reward.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(14),
                  accentColor: isUnlocked ? _neonGreen : _pureWhite,
                  fallbackIcon: Icons.card_giftcard,
                  fallbackIconSize: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Reward name
              Text(
                reward.name.toUpperCase(),
                style: const TextStyle(
                  color: _pureWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _neonGreen.withValues(alpha: 0.15)
                      : _ironGrey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUnlocked
                      ? 'UNLOCKED'
                      : 'UNLOCKS AT LEVEL ${reward.levelRequired}',
                  style: TextStyle(
                    color: isUnlocked
                        ? _neonGreen
                        : _pureWhite.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Interactive task item with expandable detail on tap.
  Widget _buildInteractiveTaskItem(PortalPassTask task) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return GestureDetector(
          onTap: () {
            // For now, tasks show a simple detail snackbar.
            // Future: expand inline with sub-tasks or tips.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _deepCharcoal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: task.isCompleted
                        ? _neonGreen.withValues(alpha: 0.3)
                        : _ironGrey,
                  ),
                ),
                duration: const Duration(seconds: 2),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: _pureWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.isCompleted
                          ? 'Completed! +${task.xpReward} XP earned'
                          : '${task.currentProgress}/${task.targetProgress} — ${task.xpReward} XP reward',
                      style: TextStyle(
                        color: task.isCompleted
                            ? _neonGreen
                            : _pureWhite.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _voidBlack.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: task.isCompleted
                    ? _neonGreen.withValues(alpha: 0.3)
                    : _ironGrey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Completion indicator
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted
                        ? _neonGreen.withValues(alpha: 0.15)
                        : _ironGrey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: task.isCompleted ? _neonGreen : _ironGrey,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: _neonGreen, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? _pureWhite.withValues(alpha: 0.5)
                              : _pureWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            task.targetGame.toUpperCase(),
                            style: TextStyle(
                              color: _neonGreen.withValues(alpha: 0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${task.xpReward} XP',
                            style: TextStyle(
                              color: _pureWhite.withValues(alpha: 0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress or tap hint
                if (!task.isCompleted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${task.currentProgress}/${task.targetProgress}',
                        style: const TextStyle(
                          color: _pureWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: task.progressPercent,
                            minHeight: 3,
                            backgroundColor: _ironGrey,
                            valueColor: const AlwaysStoppedAnimation(
                              _neonGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: _pureWhite.withValues(alpha: 0.2),
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SPECIAL REWARDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSpecialRewards() {
    if (ch.specialRewards.isEmpty) {
      return Text(
        'No special rewards yet.',
        style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ch.specialRewards.length,
        itemBuilder: (context, index) {
          final reward = ch.specialRewards[index];
          return Container(
            width: 120,
            margin: EdgeInsets.only(
              right: index < ch.specialRewards.length - 1 ? 12 : 0,
            ),
            decoration: BoxDecoration(
              color: _voidBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: reward.isUnlocked
                    ? _neonGreen.withValues(alpha: 0.3)
                    : _ironGrey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Reward image
                Expanded(
                  child: OgaImage(
                    path: reward.image,
                    fit: BoxFit.contain,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    accentColor: _getRarityColorForString(reward.rarity),
                    fallbackIcon: Icons.auto_awesome,
                    fallbackIconSize: 28,
                  ),
                ),
                // Reward info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        reward.name.toUpperCase(),
                        style: const TextStyle(
                          color: _pureWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reward.rarity.toUpperCase(),
                        style: TextStyle(
                          color: _getRarityColorForString(reward.rarity),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // OWNERSHIP HISTORY
  // ═══════════════════════════════════════════════════════════

  Widget _buildOwnershipHistory() {
    if (ch.ownershipHistory.isEmpty) {
      return Text(
        'No ownership history recorded.',
        style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
      );
    }

    // Reverse so current owner is at top
    final owners = ch.ownershipHistory.reversed.toList();

    return Column(
      children: owners.asMap().entries.map((entry) {
        final index = entry.key;
        final owner = entry.value;
        final isLast = index == owners.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline rail ─────────────────────────
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    // Node
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: owner.isCurrent
                            ? _neonGreen.withValues(alpha: 0.2)
                            : _voidBlack,
                        border: Border.all(
                          color: owner.isCurrent
                              ? _neonGreen
                              : _ironGrey.withValues(alpha: 0.5),
                          width: owner.isCurrent ? 2.5 : 1.5,
                        ),
                        boxShadow: owner.isCurrent
                            ? [
                                BoxShadow(
                                  color: _neonGreen.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: owner.isCurrent
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _neonGreen,
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Connector line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: _ironGrey.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Owner card ────────────────────────────
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: owner.isCurrent
                        ? _neonGreen.withValues(alpha: 0.04)
                        : _voidBlack.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: owner.isCurrent
                          ? _neonGreen.withValues(alpha: 0.2)
                          : _ironGrey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      OgaAvatarImage(
                        url: owner.avatarUrl,
                        size: 36,
                        fallbackLetter: owner.username.length > 1
                            ? owner.username[1]
                            : '?',
                        borderColor: owner.isCurrent ? _neonGreen : _ironGrey,
                        borderWidth: owner.isCurrent ? 1.5 : 0,
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    owner.username,
                                    style: TextStyle(
                                      color: owner.isCurrent
                                          ? _pureWhite
                                          : _pureWhite.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (owner.isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _neonGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        color: _neonGreen,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Event icon
                                Icon(
                                  owner.isCurrent
                                      ? Icons.verified
                                      : Icons.swap_horiz,
                                  size: 12,
                                  color: owner.isCurrent
                                      ? _neonGreen.withValues(alpha: 0.5)
                                      : _pureWhite.withValues(alpha: 0.25),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  owner.isCurrent
                                      ? 'Acquired ${_formatDate(owner.ownedFrom)}'
                                      : '${_formatDate(owner.ownedFrom)} — ${_formatDate(owner.ownedUntil!)}',
                                  style: TextStyle(
                                    color: _pureWhite.withValues(alpha: 0.3),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GAMEPLAY GALLERY
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameplayGallery() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ch.gameplayMedia.length,
        itemBuilder: (context, index) {
          final media = ch.gameplayMedia[index];
          return GestureDetector(
            onTap: () => _openLightbox(context, index),
            child: Container(
              width: 240,
              margin: EdgeInsets.only(
                right: index < ch.gameplayMedia.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                color: _voidBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ironGrey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screenshot image with play/zoom hint
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        OgaImage(
                          path: media.imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          accentColor: _neonGreen,
                          fallbackIcon: Icons.image,
                          fallbackIconSize: 40,
                        ),
                        // Zoom hint overlay
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _voidBlack.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.fullscreen,
                              color: _pureWhite.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ),
                        ),
                        // Image counter badge
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _voidBlack.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}/${ch.gameplayMedia.length}',
                              style: TextStyle(
                                color: _pureWhite.withValues(alpha: 0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.gameName.toUpperCase(),
                          style: TextStyle(
                            color: _neonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          media.caption,
                          style: TextStyle(
                            color: _pureWhite.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Opens a full-screen lightbox overlay with PageView swipe navigation.
  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: _voidBlack.withValues(alpha: 0.95),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _GameplayLightbox(
            media: ch.gameplayMedia,
            initialIndex: initialIndex,
            animation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITY WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _deepCharcoal.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.arrow_back, color: _pureWhite, size: 18),
      ),
    );
  }

  Widget _buildShareButton() {
    return IconButton(
      onPressed: () {
        // TODO: Share this character
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _deepCharcoal.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.share, color: _pureWhite, size: 18),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == _ironGrey ? _pureWhite.withValues(alpha: 0.7) : color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Color Helpers ────────────────────────────────────────

  Color _getRarityColor() => _getRarityColorForString(ch.rarity);

  Color _getRarityColorForString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color(0xFFAB47BC); // Purple
      case 'rare':
        return const Color(0xFF42A5F5); // Blue
      default:
        return _ironGrey;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// ANIMATED BUILDER HELPER
// ═══════════════════════════════════════════════════════════════════
// Flutter doesn't have AnimatedBuilder — this is a custom widget
// that wraps AnimatedWidget pattern for cleaner glow animations.

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class _GameplayLightbox extends StatefulWidget {
  final List<GameplayMedia> media;
  final int initialIndex;
  final Animation<double> animation;

  const _GameplayLightbox({
    required this.media,
    required this.initialIndex,
    required this.animation,
  });

  @override
  State<_GameplayLightbox> createState() => _GameplayLightboxState();
}

class _GameplayLightboxState extends State<_GameplayLightbox> {
  late PageController _pageController;
  late int _currentIndex;

  static const Color _voidBlack = Color(0xFF000000);
  static const Color _deepCharcoal = Color(0xFF121212);
  static const Color _neonGreen = Color(0xFF39FF14);
  static const Color _ironGrey = Color(0xFF2C2C2C);
  static const Color _pureWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Swipeable image pages ─────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: media.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = media[index];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 3.0,
                      child: OgaImage(
                        path: item.imageUrl,
                        fit: BoxFit.contain,
                        accentColor: _neonGreen,
                        fallbackIcon: Icons.image,
                        fallbackIconSize: 64,
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Top bar: close + counter ──────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _deepCharcoal.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _ironGrey.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: _pureWhite,
                        size: 20,
                      ),
                    ),
                  ),
                  // Image counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _deepCharcoal.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _ironGrey.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} OF ${media.length}',
                      style: const TextStyle(
                        color: _pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom caption bar ────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _deepCharcoal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ironGrey.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media[_currentIndex].gameName.toUpperCase(),
                      style: const TextStyle(
                        color: _neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      media[_currentIndex].caption,
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Page dots
                    if (media.length > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(media.length, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _neonGreen
                                  : _ironGrey.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
