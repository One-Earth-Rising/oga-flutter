import 'package:flutter/material.dart';
import '../models/oga_character.dart';
import '../services/friend_service.dart';
import 'character_detail_screen.dart';
import '../config/oga_storage.dart';
import '../widgets/character_card.dart';

/// Authenticated view of a friend's profile and character library.
/// Navigated to by tapping a friend row in the Friends tab.
class FriendProfileScreen extends StatefulWidget {
  final FriendProfile friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  bool _isGridView = true;

  FriendProfile get friend => widget.friend;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: voidBlack,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTopBar()),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildStatsBar()),
          SliverToBoxAdapter(child: _buildLibraryHeader()),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 40),
            sliver: _isGridView ? _buildCharacterGrid() : _buildCharacterList(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 900;

  // ═══════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _isMobile ? 8 : 40,
        MediaQuery.of(context).padding.top + 8,
        _isMobile ? 16 : 40,
        8,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: deepCharcoal.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              '${friend.name.toUpperCase()}\'S PROFILE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Friend badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: neonGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  color: neonGreen.withValues(alpha: 0.7),
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  'FRIEND',
                  style: TextStyle(
                    color: neonGreen.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
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
  // HERO
  // ═══════════════════════════════════════════════════════════

  Widget _buildHero() {
    // Get the friend's starter character for the hero background
    final starterChar = friend.starterCharacter != null
        ? OGACharacter.fromId(friend.starterCharacter!)
        : OGACharacter.allCharacters.first;

    return Stack(
      children: [
        // Background — character art
        Container(
          height: _isMobile ? 280 : 320,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(OgaStorage.resolve(starterChar.imagePath)),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              onError: (_, __) {},
            ),
          ),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                voidBlack.withValues(alpha: 0.6),
                voidBlack,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Profile info overlay
        Positioned(
          left: _isMobile ? 20 : 60,
          bottom: 16,
          right: _isMobile ? 20 : 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: friend.characterColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: friend.characterColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: friend.avatarUrl != null
                      ? Image.network(
                          friend.avatarUrl!,
                          height: 72,
                          width: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackAvatar(72),
                        )
                      : _buildFallbackAvatar(72),
                ),
              ),
              const SizedBox(width: 16),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isMobile ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    if (friend.email.isNotEmpty)
                      Text(
                        friend.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    if (friend.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withValues(alpha: 0.25),
                              size: 11,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Joined ${_formatDate(friend.createdAt!)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 11,
                              ),
                            ),
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

  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: deepCharcoal,
      child: Center(
        child: Text(
          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: friend.characterColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATS BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsBar() {
    final ownedCount = friend.starterCharacter != null ? 1 : 0;
    final totalChars = OGACharacter.allCharacters.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isMobile ? 16 : 40,
        20,
        _isMobile ? 16 : 40,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ironGrey),
        ),
        child: Row(
          children: [
            _buildStat('CHARACTERS', '$ownedCount / $totalChars'),
            _buildStatDivider(),
            _buildStat(
              'STARTER',
              friend.starterCharacter?.toUpperCase() ?? 'NONE',
            ),
            _buildStatDivider(),
            _buildStat('INVITE CODE', friend.inviteCode ?? '—'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: neonGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: ironGrey,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LIBRARY HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildLibraryHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isMobile ? 16 : 40,
        24,
        _isMobile ? 16 : 40,
        16,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: neonGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${friend.name.split(' ').first.toUpperCase()}\'S LIBRARY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${OGACharacter.allCharacters.length} CHARACTERS',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Grid/list toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ironGrey, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isGridView = true),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isGridView ? ironGrey : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.grid_view,
                      color: _isGridView ? Colors.white : Colors.white24,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isGridView = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: !_isGridView ? ironGrey : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.view_list,
                      color: !_isGridView ? Colors.white : Colors.white24,
                      size: 14,
                    ),
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
  // CHARACTER GRID
  // ═══════════════════════════════════════════════════════════

  Widget _buildCharacterGrid() {
    final chars = OGACharacter.allCharacters;
    final ownedId = friend.starterCharacter;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isMobile ? 2 : 5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final ch = chars[index];
        final owned = ch.id == ownedId; // Only their starter is owned

        return GestureDetector(
          onTap: () => _openCharacterDetail(ch, owned),
          child: CharacterCard(
            character: ch,
            isOwned: owned,
            progress: owned ? 1.0 : 0.0, // Shows 100% if they own it
          ),
        );
      }, childCount: chars.length), // Fixed the * 2 doubling bug!
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CHARACTER LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildCharacterList() {
    final chars = OGACharacter.allCharacters;
    final ownedId = friend.starterCharacter;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ch = chars[index];
        final owned = ch.id == ownedId;
        final charColor = ch.cardColor;

        return GestureDetector(
          onTap: () => _openCharacterDetail(ch, owned),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: owned
                    ? ch.glowColor.withValues(alpha: 0.4)
                    : ironGrey.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    OgaStorage.resolve(
                      ch.thumbnailImage.isNotEmpty
                          ? ch.thumbnailImage
                          : ch.heroImage,
                    ),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: charColor,
                      child: const Icon(Icons.person, color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ch.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            ch.ip,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 12,
                            ),
                          ),
                          if (ch.gameVariations.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: neonGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${ch.gameVariations.length} GAMES',
                                style: TextStyle(
                                  color: neonGreen.withValues(alpha: 0.7),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (owned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'OWNED',
                      style: TextStyle(
                        color: neonGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.lock_outline,
                    color: Colors.white.withValues(alpha: 0.15),
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }, childCount: chars.length), // Fixed the allChars doubling bug here too!
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════

  void _openCharacterDetail(OGACharacter ch, bool owned) {
    Navigator.pushNamed(context, '/character/${ch.id}');
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
