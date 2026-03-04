import 'package:flutter/material.dart';
import '../models/oga_character.dart';
import '../config/oga_storage.dart';

/// Heimdal-aesthetic character card with IP-colored background,
/// animated glow for owned characters, and progress ring.
class CharacterCard extends StatefulWidget {
  final OGACharacter character;
  final bool isOwned;
  final bool isBorrowed;
  final bool isLentOut;
  final String? lendReturnDate;
  final double progress;

  const CharacterCard({
    super.key,
    required this.character,
    this.isOwned = false,
    this.isBorrowed = false,
    this.isLentOut = false,
    this.lendReturnDate,
    this.progress = 0.0,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  static const Color neonGreen = Color(0xFF39FF14);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);
  static const Color _lendCyan = Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.isOwned && !widget.isLentOut) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return AnimatedContainer(
              // 1. Bumped duration for a more premium feel
              duration: const Duration(milliseconds: 300),

              // 2. Smoother, more organic deceleration
              curve: Curves.easeOutCubic,

              // 3. Added alignment so it zooms from the center
              alignment: Alignment.center,

              transform: Matrix4.diagonal3Values(
                _isHovered ? 1.03 : 1.0,
                _isHovered ? 1.03 : 1.0,
                1.0,
              ),
              decoration: BoxDecoration(
                color: deepCharcoal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isLentOut
                      ? ironGrey.withValues(alpha: 0.5)
                      : widget.isBorrowed
                      ? _lendCyan.withValues(alpha: _glowAnimation.value)
                      : widget.isOwned
                      ? neonGreen.withValues(alpha: _glowAnimation.value)
                      : (_isHovered
                            ? ironGrey.withValues(alpha: 0.8)
                            : ironGrey),
                  width:
                      (widget.isOwned || widget.isBorrowed) && !widget.isLentOut
                      ? 1.5
                      : 1,
                ),
                boxShadow: widget.isLentOut
                    ? []
                    : widget.isBorrowed
                    ? [
                        BoxShadow(
                          color: _lendCyan.withValues(
                            alpha: _glowAnimation.value * 0.25,
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : widget.isOwned
                    ? [
                        BoxShadow(
                          color: widget.character.glowColor.withValues(
                            alpha: _glowAnimation.value * 0.3,
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildImageSection()),
                    _buildInfoBar(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── IMAGE SECTION ────────────────────────────────────────

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // IP-colored gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.character.cardColor.withValues(alpha: 0.6),
                widget.character.cardColor.withValues(alpha: 0.2),
                deepCharcoal,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Character image
        Positioned.fill(
          child: Image.network(
            OgaStorage.resolve(
              widget.character.imagePath,
            ), // <--- Wrapped here!
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.person,
                color: widget.character.cardColor.withValues(alpha: 0.5),
                size: 48,
              ),
            ),
          ),
        ),

        // Locked overlay (not owned AND not borrowed)
        if (!widget.isOwned && !widget.isBorrowed)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

        // Lent-out dimming overlay
        if (widget.isLentOut)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

        // Lock icon (not owned, not borrowed)
        if (!widget.isOwned && !widget.isBorrowed)
          const Positioned(
            top: 8,
            left: 8,
            child: Icon(Icons.lock_outline, color: Colors.white38, size: 16),
          ),

        // BORROWED badge (top-left)
        if (widget.isBorrowed)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _lendCyan.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake_outlined, color: Colors.white, size: 10),
                  SizedBox(width: 3),
                  Text(
                    'BORROWED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // LENT OUT badge (top-left)
        if (widget.isLentOut)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: ironGrey.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.call_made,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'LENT OUT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Game count badge
        if (widget.character.gameVariations.isNotEmpty)
          Positioned(bottom: 8, left: 8, child: _buildGameBadge()),

        // Menu icon (owned only, not lent out)
        if (widget.isOwned && !widget.isLentOut && !widget.isBorrowed)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.more_horiz,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),

        // Countdown badge for borrowed (top-right)
        if (widget.isBorrowed && widget.lendReturnDate != null)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _lendCyan.withValues(alpha: 0.3)),
              ),
              child: Text(
                _formatCountdown(widget.lendReturnDate!),
                style: TextStyle(
                  color: _lendCyan.withValues(alpha: 0.9),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameBadge() {
    final gameCount = widget.character.gameVariations.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ironGrey, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videogame_asset, color: neonGreen, size: 10),
          const SizedBox(width: 3),
          Text(
            '$gameCount ${gameCount == 1 ? "GAME" : "GAMES"}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO BAR ─────────────────────────────────────────────

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: deepCharcoal,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  widget.character.ip,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.isOwned || widget.isBorrowed) _buildProgressRing(),
        ],
      ),
    );
  }

  String _formatCountdown(String returnDateStr) {
    try {
      final returnDate = DateTime.parse(returnDateStr);
      final diff = returnDate.difference(DateTime.now());
      if (diff.isNegative) return 'OVERDUE';
      if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
      if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
      return '${diff.inMinutes}m';
    } catch (_) {
      return '';
    }
  }

  Widget _buildProgressRing() {
    final percent = (widget.progress * 100).toInt();
    return SizedBox(
      height: 30,
      width: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: widget.progress,
            strokeWidth: 2,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(
              widget.isBorrowed ? _lendCyan : neonGreen,
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
