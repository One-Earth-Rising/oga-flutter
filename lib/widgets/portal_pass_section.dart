import 'package:flutter/material.dart';
import '../services/portal_pass_service.dart';

// ═══════════════════════════════════════════════════════════════
// PORTAL PASS SECTION
// Displays a character's portal pass card.
// Handles owned (progress + tasks) and locked (FOMO teaser) states.
//
// Usage in character_detail_screen.dart:
//   PortalPassSection(
//     characterId: ch.id,
//     characterName: ch.name,
//     isOwned: owned,
//     onViewPass: () => Navigator.pushNamed(context, '/portal-pass',
//       arguments: {'characterId': ch.id}),
//   )
// ═══════════════════════════════════════════════════════════════

const Color _neonGreen = Color(0xFF39FF14);
const Color _deepCharcoal = Color(0xFF121212);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _voidBlack = Color(0xFF000000);
const Color _pureWhite = Color(0xFFFFFFFF);

// ═══════════════════════════════════════════════════════════════
// PORTAL PASS SECTION
// ═══════════════════════════════════════════════════════════════

class PortalPassSection extends StatefulWidget {
  final String characterId;
  final String characterName;
  final bool isOwned;
  final VoidCallback? onViewPass;

  const PortalPassSection({
    super.key,
    required this.characterId,
    required this.characterName,
    required this.isOwned,
    this.onViewPass,
  });

  @override
  State<PortalPassSection> createState() => _PortalPassSectionState();
}

class _PortalPassSectionState extends State<PortalPassSection> {
  PortalPassData? _pass;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pass = await PortalPassService.getForCharacter(widget.characterId);
    if (mounted)
      setState(() {
        _pass = pass;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: _neonGreen),
          ),
        ),
      );
    }
    if (_pass == null) return const SizedBox.shrink();
    return _PassCard(
      pass: _pass!,
      characterName: widget.characterName,
      isOwned: widget.isOwned,
      onViewPass: widget.onViewPass,
    );
  }
}

// ─── Main pass card ─────────────────────────────────────────────

class _PassCard extends StatelessWidget {
  final PortalPassData pass;
  final String characterName;
  final bool isOwned;
  final VoidCallback? onViewPass;

  const _PassCard({
    required this.pass,
    required this.characterName,
    required this.isOwned,
    this.onViewPass,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PORTAL PASS',
          style: TextStyle(
            color: _pureWhite,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _deepCharcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ironGrey),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(context),
              const Divider(color: _ironGrey, height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOwned) ...[
                      _buildProgressBlock(),
                      const SizedBox(height: 20),
                      _buildTaskList(),
                    ] else ...[
                      _buildLockedTeaser(),
                    ],
                    const SizedBox(height: 20),
                    _buildViewPassButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Card header: brand logo + pass name + season + expiry ──

  Widget _buildCardHeader(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final logoSize = isWeb ? 80.0 : 56.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pass.name.toUpperCase(),
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
                if (pass.seasonName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    pass.seasonName!.toUpperCase(),
                    style: const TextStyle(
                      color: _neonGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _expiryBadge(),
              ],
            ),
          ),
          // Brand logo — top-right, larger on web
          if (pass.brandLogoUrl != null) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: logoSize,
              height: logoSize,
              child: Image.network(
                pass.brandLogoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _expiryBadge() {
    final label = pass.expiryLabel;
    if (label.isEmpty) return const SizedBox.shrink();
    final isUrgent =
        label.contains('D LEFT') ||
        label.contains('H LEFT') ||
        label.contains('M LEFT') ||
        label == 'EXPIRED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: 0.15)
            : _ironGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isUrgent ? Colors.red.withValues(alpha: 0.4) : _ironGrey,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isUrgent ? Colors.red[300] : Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ─── Owned: XP progress bar ──────────────────────────────────

  Widget _buildProgressBlock() {
    final completed = pass.completedTasks;
    final total = pass.totalTasks;
    final pct = pass.progressPercent;
    final totalXp = pass.tasks.fold(0, (s, t) => s + t.xpReward);
    final earnedXp = pass.tasks
        .where((t) => t.isCompleted)
        .fold(0, (s, t) => s + t.xpReward);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completed / $total COMPLETED',
              style: const TextStyle(
                color: _pureWhite,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text(
              '$earnedXp / $totalXp XP',
              style: const TextStyle(
                color: _neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: _ironGrey,
            borderRadius: BorderRadius.circular(3),
          ),
          child: LayoutBuilder(
            builder: (_, c) => Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: c.maxWidth * pct,
                  decoration: BoxDecoration(
                    color: _neonGreen,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: _neonGreen.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (pass.isComplete) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _neonGreen.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: _neonGreen, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'PASS COMPLETE — CLAIM YOUR REWARD',
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Owned: task list (condensed) ───────────────────────────

  Widget _buildTaskList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBJECTIVES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        ...pass.tasks.map((t) => _TaskRow(task: t)),
      ],
    );
  }

  // ─── Locked: FOMO teaser ─────────────────────────────────────

  Widget _buildLockedTeaser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pass.description != null) ...[
          Text(
            pass.description!,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'OBJECTIVES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        ...pass.tasks.map((t) => _TaskRow(task: t, forceLocked: true)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _neonGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _neonGreen.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: _neonGreen, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unlock this character to start earning XP on this pass.',
                  style: TextStyle(
                    color: _neonGreen.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── VIEW FULL PASS button ───────────────────────────────────

  Widget _buildViewPassButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onViewPass,
        icon: const Icon(Icons.open_in_new, size: 14),
        label: const Text(
          'VIEW FULL PASS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _neonGreen,
          side: BorderSide(color: _neonGreen.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ─── Individual task row ─────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final PortalPassTaskData task;
  final bool forceLocked;

  const _TaskRow({required this.task, this.forceLocked = false});

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted && !forceLocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? _neonGreen.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: done
                    ? _neonGreen.withValues(alpha: 0.8)
                    : forceLocked
                    ? Colors.white12
                    : Colors.white24,
              ),
            ),
            child: Icon(
              done
                  ? Icons.check
                  : forceLocked
                  ? Icons.lock_outline
                  : Icons.radio_button_unchecked,
              size: 12,
              color: done
                  ? _neonGreen
                  : forceLocked
                  ? Colors.white24
                  : Colors.white38,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title.toUpperCase(),
              style: TextStyle(
                color: done
                    ? Colors.white38
                    : forceLocked
                    ? Colors.white30
                    : _pureWhite,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white24,
              ),
            ),
          ),
          Text(
            '+${task.xpReward} XP',
            style: TextStyle(
              color: done
                  ? Colors.white24
                  : forceLocked
                  ? Colors.white12
                  : _neonGreen.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPECIAL REWARD SECTION
// Shows the portal pass completion reward (the bonus OGA).
// Always visible — locked state for non-owners, unlocked for
// owners who have completed the pass.
// ═══════════════════════════════════════════════════════════════

class SpecialRewardSection extends StatefulWidget {
  final String characterId;
  final bool isOwned;

  const SpecialRewardSection({
    super.key,
    required this.characterId,
    required this.isOwned,
  });

  @override
  State<SpecialRewardSection> createState() => _SpecialRewardSectionState();
}

class _SpecialRewardSectionState extends State<SpecialRewardSection> {
  PortalPassData? _pass;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PortalPassService.getForCharacter(widget.characterId);
    if (mounted)
      setState(() {
        _pass = p;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pass == null) return const SizedBox.shrink();
    if (_pass!.specialRewardName == null) return const SizedBox.shrink();
    return _SpecialRewardCard(pass: _pass!, isOwned: widget.isOwned);
  }
}

class _SpecialRewardCard extends StatelessWidget {
  final PortalPassData pass;
  final bool isOwned;

  const _SpecialRewardCard({required this.pass, required this.isOwned});

  @override
  Widget build(BuildContext context) {
    final rewardUnlocked = isOwned && pass.isComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SPECIAL REWARD',
          style: TextStyle(
            color: _pureWhite,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _deepCharcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rewardUnlocked
                  ? _neonGreen.withValues(alpha: 0.5)
                  : _ironGrey,
            ),
          ),
          child: Stack(
            children: [
              // Glow when unlocked
              if (rewardUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        colors: [
                          _neonGreen.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        center: Alignment.topRight,
                        radius: 1.2,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRewardImage(rewardUnlocked),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!rewardUnlocked)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LOCKED',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          Text(
                            (pass.specialRewardName ?? '').toUpperCase(),
                            style: TextStyle(
                              color: rewardUnlocked ? _neonGreen : _pureWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (pass.specialRewardDescription != null)
                            Text(
                              pass.specialRewardDescription!,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          const SizedBox(height: 12),
                          _progressPill(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardImage(bool unlocked) {
    final imgUrl = pass.specialRewardImageUrl;
    return Container(
      width: 72,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked ? _neonGreen.withValues(alpha: 0.5) : _ironGrey,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imgUrl != null
          ? Image.network(
              imgUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _lockedPlaceholder(),
            )
          : _lockedPlaceholder(),
    );
  }

  Widget _lockedPlaceholder() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, color: _neonGreen.withValues(alpha: 0.3), size: 28),
          const SizedBox(height: 4),
          const Text(
            '???',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressPill() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pass.progressPercent,
              backgroundColor: _ironGrey,
              valueColor: const AlwaysStoppedAnimation(_neonGreen),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${pass.completedTasks}/${pass.totalTasks}',
          style: const TextStyle(
            color: _neonGreen,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BRAND LOGO BADGE
// Positioned top-right in the hero Stack.
// Responsive: 72px on web, 48px on mobile.
// Reads brand logo URL from the character's portal pass.
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// CO-BRAND LOGO BADGE
// Pane edge + portal pass section header.
// Shows the brand × OGA cobrand logo (brand_logo_url).
// ═══════════════════════════════════════════════════════════════

class CoBrandLogoBadge extends StatefulWidget {
  final String characterId;

  const CoBrandLogoBadge({super.key, required this.characterId});

  @override
  State<CoBrandLogoBadge> createState() => _CoBrandLogoBadgeState();
}

class _CoBrandLogoBadgeState extends State<CoBrandLogoBadge> {
  PortalPassData? _pass;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PortalPassService.getForCharacter(widget.characterId);
    if (mounted && p?.brandLogoUrl != null) setState(() => _pass = p);
  }

  @override
  Widget build(BuildContext context) {
    if (_pass?.brandLogoUrl == null) return const SizedBox.shrink();
    final isWeb = MediaQuery.of(context).size.width > 600;
    final size = isWeb ? 72.0 : 48.0;
    final padding = isWeb ? 16.0 : 12.0;

    return Positioned(
      top: padding,
      right: padding,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          _pass!.brandLogoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BRAND LOGO BADGE
// Hero card corner overlay.
// Shows the solo brand logo (brand_card_logo_url).
// ═══════════════════════════════════════════════════════════════

class BrandLogoBadge extends StatefulWidget {
  final String characterId;

  const BrandLogoBadge({super.key, required this.characterId});

  @override
  State<BrandLogoBadge> createState() => _BrandLogoBadgeState();
}

class _BrandLogoBadgeState extends State<BrandLogoBadge> {
  PortalPassData? _pass;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PortalPassService.getForCharacter(widget.characterId);
    if (mounted && p?.brandCardLogoUrl != null) setState(() => _pass = p);
  }

  @override
  Widget build(BuildContext context) {
    if (_pass?.brandCardLogoUrl == null) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      right: 12,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          _pass!.brandCardLogoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
