import 'package:flutter/material.dart';
import '../models/oga_character.dart';
import '../services/friend_service.dart';

/// Guest view of a character detail — no auth required.
/// Shows character info but locks all interactions behind a sign-up wall.
class InviteCharacterDetail extends StatelessWidget {
  final OGACharacter character;
  final bool isOwnedByInviter;
  final InviterProfile inviter;
  final VoidCallback onSignUp;

  const InviteCharacterDetail({
    super.key,
    required this.character,
    required this.isOwnedByInviter,
    required this.inviter,
    required this.onSignUp,
  });

  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color ironGrey = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: voidBlack,
      body: isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobile(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Hero image
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.85,
                    child: Image.asset(
                      character.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: character.cardColor),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            voidBlack.withValues(alpha: 0.8),
                            voidBlack,
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 48,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: voidBlack.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Inviter badge
                  if (isOwnedByInviter)
                    Positioned(top: 48, right: 16, child: _buildOwnerBadge()),
                ],
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCharacterInfo(context),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        // Bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildDetailCTA(context),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════

  Widget _buildDesktop(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            // Left: Character image
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      character.imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) =>
                          Container(color: character.cardColor),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          voidBlack.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 24,
                    left: 24,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: voidBlack.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right: Info panel
            Expanded(
              flex: 5,
              child: Container(
                color: voidBlack,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 40, 60, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOwnedByInviter) ...[
                        _buildOwnerBadge(),
                        const SizedBox(height: 20),
                      ],
                      _buildCharacterInfo(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Bottom CTA
        Positioned(
          right: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.5,
          child: _buildDetailCTA(context),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CHARACTER INFO
  // ═══════════════════════════════════════════════════════════

  Widget _buildCharacterInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + IP
        Text(
          character.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          character.ip,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // Description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: deepCharcoal,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: neonGreen.withValues(alpha: 0.5),
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  character.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Game variations (locked)
        _buildLockedSection(
          icon: Icons.sports_esports,
          title: 'GAME VARIATIONS',
          subtitle: '${character.gameVariations.length} games available',
          description: 'Sign up to see which games this character works in',
        ),
        const SizedBox(height: 12),

        // Portal pass (locked)
        _buildLockedSection(
          icon: Icons.all_inclusive,
          title: 'PORTAL PASS',
          subtitle: 'Cross-game progression',
          description: 'Create an account to unlock Portal Pass tracking',
        ),
        const SizedBox(height: 12),

        // Trade (locked)
        if (isOwnedByInviter)
          _buildLockedSection(
            icon: Icons.swap_horiz,
            title: 'REQUEST TRADE',
            subtitle: 'Ask ${inviter.displayName} to trade this character',
            description: 'Sign up to send trade requests to other players',
          ),
      ],
    );
  }

  Widget _buildLockedSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return GestureDetector(
      onTap: onSignUp,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ironGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.3),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Lock + CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: neonGreen.withValues(alpha: 0.6),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SIGN UP',
                    style: TextStyle(
                      color: neonGreen.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // OWNER BADGE
  // ═══════════════════════════════════════════════════════════

  Widget _buildOwnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: neonGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: neonGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: neonGreen.withValues(alpha: 0.8),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'OWNED BY ${inviter.displayName.toUpperCase()}',
            style: TextStyle(
              color: neonGreen.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM CTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            voidBlack.withValues(alpha: 0.0),
            voidBlack.withValues(alpha: 0.9),
            voidBlack,
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onSignUp,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: neonGreen,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: neonGreen.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch, color: Colors.black, size: 18),
              SizedBox(width: 10),
              Text(
                'SIGN UP TO UNLOCK',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
