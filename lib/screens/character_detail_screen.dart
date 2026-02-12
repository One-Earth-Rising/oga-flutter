import 'package:flutter/material.dart';
import '../models/oga_character.dart';

/// Character detail screen matching the Figma "Menu score" design.
/// Desktop: Split-pane (info sidebar left, game variations right)
/// Mobile: Stacked vertically
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

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  // V2 Brand Colors
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);
  static const Color surfaceCard = Color(0xFF1A1A1A);

  int _selectedVariationIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: voidBlack,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Split pane
  // ═══════════════════════════════════════════════════════════

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Info sidebar (scrollable)
            SizedBox(width: 400, child: _buildInfoSidebar()),

            // Right: Game variations
            Expanded(child: _buildGameVariationsPanel()),
          ],
        ),

        // Close button
        Positioned(top: 16, right: 16, child: _buildCloseButton()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT — Stacked
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game variations (horizontal scroll)
              SizedBox(height: 450, child: _buildGameVariationsMobile()),

              // Info content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCharacterHeader(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildDescription(),
                    const SizedBox(height: 32),
                    if (widget.isOwned && widget.character.portalPass != null)
                      _buildPortalPassSection(),
                    if (widget.isOwned && widget.character.portalPass != null)
                      const SizedBox(height: 32),
                    if (widget.character.owners.isNotEmpty)
                      _buildOwnedBySection(),
                    if (!widget.isOwned) ...[
                      const SizedBox(height: 32),
                      _buildLockedSection(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Close / Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: _buildCloseButton(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INFO SIDEBAR (Desktop left panel)
  // ═══════════════════════════════════════════════════════════

  Widget _buildInfoSidebar() {
    return Container(
      color: surfaceCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OGA Container icon
            _buildOGAIcon(),
            const SizedBox(height: 24),

            // Character header
            _buildCharacterHeader(),
            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
            const SizedBox(height: 24),

            // Description
            _buildDescription(),
            const SizedBox(height: 32),

            // Portal Pass (owned only)
            if (widget.isOwned && widget.character.portalPass != null) ...[
              _buildPortalPassSection(),
              const SizedBox(height: 32),
            ],

            // Owned By
            if (widget.character.owners.isNotEmpty) ...[
              _buildOwnedBySection(),
              const SizedBox(height: 32),
            ],

            // Character Locked (unowned)
            if (!widget.isOwned) ...[
              _buildLockedSection(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  // ─── OGA Icon ─────────────────────────────────────────────

  Widget _buildOGAIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ironGrey),
      ),
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          height: 28,
          errorBuilder: (_, __, ___) => Transform.rotate(
            angle: 0.785, // 45 degrees
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.hexagon_outlined,
                color: Colors.white38,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Character Header ─────────────────────────────────────

  Widget _buildCharacterHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.character.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            height: 1.1,
          ),
        ),
        if (widget.character.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.character.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Action Buttons ───────────────────────────────────────

  Widget _buildActionButtons() {
    if (!widget.isOwned) return const SizedBox();

    return Row(
      children: [
        _buildPillButton('SELL', true),
        const SizedBox(width: 10),
        _buildPillButton('SHARE', false),
      ],
    );
  }

  Widget _buildPillButton(String label, bool primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary ? neonGreen : ironGrey, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? neonGreen : Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ─── Description ──────────────────────────────────────────

  Widget _buildDescription() {
    return Text(
      widget.character.description,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 14,
        height: 1.7,
      ),
    );
  }

  // ─── Portal Pass ──────────────────────────────────────────

  Widget _buildPortalPassSection() {
    final pass = widget.character.portalPass!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with progress ring
        Row(
          children: [
            const Expanded(
              child: Text(
                'PROGRESS PORTAL PASS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            _buildPortalPassRing(pass),
          ],
        ),
        const SizedBox(height: 16),

        // Task list
        ...pass.tasks.map((task) => _buildTaskRow(task)),
      ],
    );
  }

  Widget _buildPortalPassRing(PortalPass pass) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pass.progress,
            strokeWidth: 3,
            backgroundColor: ironGrey,
            valueColor: const AlwaysStoppedAnimation(neonGreen),
          ),
          Text(
            pass.percentLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(PortalPassTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.isComplete ? neonGreen.withValues(alpha: 0.2) : ironGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Task number
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: task.isComplete
                  ? neonGreen.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: task.isComplete
                    ? neonGreen.withValues(alpha: 0.4)
                    : ironGrey,
              ),
            ),
            child: Center(
              child: Text(
                '${task.index}',
                style: TextStyle(
                  color: task.isComplete ? neonGreen : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Task icon placeholder
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.character.cardColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              task.iconPath ?? widget.character.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                task.isComplete ? Icons.check : Icons.star,
                color: task.isComplete
                    ? neonGreen
                    : widget.character.cardColor.withValues(alpha: 0.5),
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Task title
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.isComplete ? Colors.white70 : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Progress
          Text(
            task.progressLabel,
            style: TextStyle(
              color: task.isComplete ? neonGreen : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Owned By ─────────────────────────────────────────────

  Widget _buildOwnedBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'OWNED BY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ironGrey),
              ),
              child: const Text(
                'SEE ALL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Owner list
        ...widget.character.owners.map((owner) => _buildOwnerRow(owner)),
      ],
    );
  }

  Widget _buildOwnerRow(OwnerRecord owner) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: deepCharcoal,
            child: owner.avatarPath != null
                ? Image.asset(
                    owner.avatarPath!,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Colors.white24,
                      size: 18,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white24, size: 18),
          ),
          const SizedBox(width: 12),

          // Name + handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  owner.handle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Value
          if (owner.value != null)
            Text(
              owner.value!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Character Locked ─────────────────────────────────────

  Widget _buildLockedSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white38, size: 28),
          const SizedBox(height: 10),
          const Text(
            'CHARACTER LOCKED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete onboarding or enter a campaign code to unlock.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: neonGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LEARN MORE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GAME VARIATIONS PANEL (Desktop right panel)
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameVariationsPanel() {
    final variations = widget.character.gameVariations;
    if (variations.isEmpty) {
      return Container(
        color: voidBlack,
        child: Center(
          child: Image.asset(
            widget.character.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      );
    }

    return Container(
      color: voidBlack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth / 2).clamp(300.0, 600.0);

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: variations.length,
            itemBuilder: (context, index) {
              return _buildVariationCard(
                variations[index],
                cardWidth,
                constraints.maxHeight,
                index,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVariationCard(
    GameVariation variation,
    double width,
    double height,
    int index,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedVariationIndex = index),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: ironGrey.withValues(alpha: 0.3), width: 1),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Character render (full height)
            Image.asset(
              variation.variationImagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: widget.character.cardColor.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: widget.character.cardColor.withValues(alpha: 0.3),
                    size: 80,
                  ),
                ),
              ),
            ),

            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      voidBlack.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Top: Game label + logo
            Positioned(
              top: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHARACTER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Game name as logo placeholder
                  Text(
                    variation.game.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Details button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text(
                      'DETAILS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Variant name (bottom)
            if (variation.variantName != null)
              Positioned(
                bottom: 20,
                left: 24,
                child: Text(
                  variation.variantName!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE GAME VARIATIONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameVariationsMobile() {
    final variations = widget.character.gameVariations;
    if (variations.isEmpty) {
      return Image.asset(
        widget.character.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(),
      );
    }

    return PageView.builder(
      itemCount: variations.length,
      onPageChanged: (i) => setState(() => _selectedVariationIndex = i),
      itemBuilder: (context, index) {
        final variation = variations[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            // Character image
            Image.asset(
              variation.variationImagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: widget.character.cardColor.withValues(alpha: 0.15),
              ),
            ),

            // Bottom fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, voidBlack],
                  ),
                ),
              ),
            ),

            // Game label
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHARACTER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    variation.game.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // Page indicator dots
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(variations.length, (i) {
                  return Container(
                    width: i == _selectedVariationIndex ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _selectedVariationIndex
                          ? neonGreen
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CLOSE BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: deepCharcoal.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: ironGrey),
        ),
        child: const Icon(Icons.close, color: Colors.white70, size: 18),
      ),
    );
  }
}
