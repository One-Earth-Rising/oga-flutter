import 'package:flutter/material.dart';
import '../models/oga_character.dart';
import '../services/friend_service.dart';
import 'character_detail_screen.dart';
import 'invite_signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/oga_image.dart';
import '../services/invite_service.dart';
import '../services/analytics_service.dart';

/// Public invite landing page — no auth required.
/// Loads inviter's profile and shows their library in a guest-friendly view.
/// Route: /#/invite/<INVITE_CODE>
class InviteLandingScreen extends StatefulWidget {
  final String inviteCode;
  final String? characterId;
  const InviteLandingScreen({
    super.key,
    required this.inviteCode,
    this.characterId,
  });

  @override
  State<InviteLandingScreen> createState() => _InviteLandingScreenState();
}

class _InviteLandingScreenState extends State<InviteLandingScreen> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color ironGrey = Color(0xFF2C2C2C);

  InviterProfile? _inviter;
  bool _isLoading = true;
  bool _notFound = false;
  bool _isGridView = true;
  bool get _isAuthenticated =>
      Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadInviterProfile();
  }

  Future<void> _loadInviterProfile() async {
    final profile = await FriendService.getPublicProfile(widget.inviteCode);
    setState(() {
      _inviter = profile;
      _notFound = profile == null;
      _isLoading = false;
    });

    if (profile != null) {
      // === TRACK INVITE CLICK (Sprint 11A) ===
      // Fires for ALL invite visits (library + character-specific)
      InviteService.recordClick(
        inviteCode: widget.inviteCode,
        characterId: widget.characterId,
      );
      AnalyticsService.trackInviteLanding(
        widget.inviteCode,
        characterId: widget.characterId,
      );

      // Auto-open specific character if characterId was in the URL
      if (widget.characterId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoOpenCharacter(widget.characterId!);
        });
      }
    }
  }

  /// Auto-navigates to a specific character's detail screen (guest mode).
  /// Triggered when URL includes character ID: /#/invite/OGA-XXXX/ryu
  void _autoOpenCharacter(String characterId) {
    try {
      final ch = OGACharacter.fromId(characterId);
      final ownedId = _inviter?.starterCharacter;
      final owned = ch.id == ownedId;
      _openGuestDetail(ch, owned);
    } catch (e) {
      debugPrint('⚠️ Character not found: $characterId');
      // Stay on library view — character ID was invalid
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: voidBlack,
        body: Center(child: CircularProgressIndicator(color: neonGreen)),
      );
    }

    if (_notFound) return _buildNotFound();

    return Scaffold(
      backgroundColor: voidBlack,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top bar
              SliverToBoxAdapter(child: _buildTopBar()),
              // Hero
              SliverToBoxAdapter(child: _buildHero()),
              // Invite banner (guests only)
              if (!_isAuthenticated)
                SliverToBoxAdapter(child: _buildInviteBanner()),
              // Library header
              SliverToBoxAdapter(child: _buildLibraryHeader()),
              // Character grid/list
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 40),
                sliver: _isGridView
                    ? _buildCharacterGrid()
                    : _buildCharacterList(),
              ),
              // Bottom spacer for CTA
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // Fixed bottom CTA (guests only)
          if (!_isAuthenticated)
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomCTA()),
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
        _isMobile ? 16 : 40,
        16,
        _isMobile ? 16 : 40,
        8,
      ),
      child: Row(
        children: [
          // OGA Logo
          Image.asset(
            'assets/logo.png',
            height: 24,
            errorBuilder: (_, __, ___) => const Text(
              'OGA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          // Sign up / back button
          GestureDetector(
            onTap: _isAuthenticated
                ? () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/dashboard', (route) => false)
                : _navigateToSignUp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: neonGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _isAuthenticated ? 'MY LIBRARY' : 'SIGN UP FREE',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
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

  // ═══════════════════════════════════════════════════════════
  // HERO — INVITER PROFILE
  // ═══════════════════════════════════════════════════════════

  Widget _buildHero() {
    final inviter = _inviter!;

    return Stack(
      children: [
        // Background
        Container(
          height: _isMobile ? 320 : 360,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/heroes/hero.png'),
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
                voidBlack.withValues(alpha: 0.7),
                voidBlack,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Profile info
        Positioned(
          left: _isMobile ? 20 : 60,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Invited by" label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: neonGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAuthenticated ? Icons.visibility : Icons.mail_outline,
                      color: neonGreen.withValues(alpha: 0.8),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAuthenticated
                          ? 'VIEWING LIBRARY'
                          : 'YOU\'VE BEEN INVITED',
                      style: TextStyle(
                        color: neonGreen.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: inviter.characterColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: inviter.characterColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: inviter.avatarUrl != null
                      ? Image.network(
                          inviter.avatarUrl!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackAvatar(inviter),
                        )
                      : _buildFallbackAvatar(inviter),
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                inviter.displayName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isMobile ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              if (inviter.username.isNotEmpty)
                Text(
                  '@${inviter.username.toUpperCase()}',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(InviterProfile inviter) {
    final char = OGACharacter.fromId(inviter.starterCharacter);
    return OgaImage(
      path: char.heroImage,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      accentColor: neonGreen,
      fallbackIcon: Icons.person,
      fallbackIconSize: 28,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INVITE BANNER
  // ═══════════════════════════════════════════════════════════

  Widget _buildInviteBanner() {
    final inviter = _inviter!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isMobile ? 16 : 40,
        20,
        _isMobile ? 16 : 40,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: neonGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: neonGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WELCOME REWARD',
                    style: TextStyle(
                      color: neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign up with ${inviter.displayName}\'s invite and receive a free character skin!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.4,
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
  // LIBRARY HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildLibraryHeader() {
    final inviter = _inviter!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isMobile ? 16 : 40,
        28,
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
            '${inviter.displayName.toUpperCase()}\'S LIBRARY',
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
  // CHARACTER GRID (guest view)
  // ═══════════════════════════════════════════════════════════

  Widget _buildCharacterGrid() {
    final chars = OGACharacter.allCharacters;
    final ownedId = _inviter?.starterCharacter;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isMobile ? 2 : 5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final ci = index % chars.length;
        final ch = chars[ci];
        final owned = index < chars.length && ch.id == ownedId;

        return GestureDetector(
          onTap: () => _openGuestDetail(ch, owned),
          child: _buildGuestCard(ch, owned),
        );
      }, childCount: chars.length),
    );
  }

  Widget _buildCharacterList() {
    final chars = OGACharacter.allCharacters;
    final ownedId = _inviter?.starterCharacter;
    final allChars = chars;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ci = index % chars.length;
        final ch = chars[ci];
        final owned = index < chars.length && ch.id == ownedId;

        return GestureDetector(
          onTap: () => _openGuestDetail(ch, owned),
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
                  child: OgaImage(
                    path: ch.heroImage,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    accentColor: ch.glowColor,
                    fallbackIcon: Icons.person,
                    fallbackIconSize: 24,
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
                      Text(
                        ch.ip,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
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
      }, childCount: allChars.length),
    );
  }

  /// Guest character card with subtle overlay indicating shared context
  Widget _buildGuestCard(OGACharacter ch, bool owned) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: owned
              ? ch.glowColor.withValues(alpha: 0.5)
              : ironGrey.withValues(alpha: 0.3),
          width: owned ? 2 : 1,
        ),
        boxShadow: owned
            ? [
                BoxShadow(
                  color: ch.glowColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Character image
            OgaImage(
              path: ch.heroImage,
              fit: BoxFit.cover,
              accentColor: ch.glowColor,
              fallbackIcon: Icons.person,
              fallbackIconSize: 40,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    voidBlack.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Name + status
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ch.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (owned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: neonGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${_inviter!.displayName.toUpperCase()} OWNS THIS',
                        style: TextStyle(
                          color: neonGreen.withValues(alpha: 0.8),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOCKED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM CTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _isMobile ? 16 : 40,
        16,
        _isMobile ? 16 : 40,
        24,
      ),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main CTA
              GestureDetector(
                onTap: _navigateToSignUp,
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
                        'JOIN OGA — GET A FREE CHARACTER',
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
              const SizedBox(height: 10),
              Text(
                'Create your free account and start building your own library',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NOT FOUND
  // ═══════════════════════════════════════════════════════════

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: voidBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
              errorBuilder: (_, __, ___) => const Text(
                'OGA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Icon(
              Icons.person_search,
              color: Colors.white.withValues(alpha: 0.15),
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'INVITE NOT FOUND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The invite code "${widget.inviteCode}" doesn\'t match any user.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _navigateToSignUp,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: neonGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SIGN UP ANYWAY',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════

  void _openGuestDetail(OGACharacter ch, bool owned) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterDetailScreen(
          character: ch,
          isOwned: owned,
          isGuest: !isAuthenticated,
          inviterName: _inviter?.displayName,
        ),
      ),
    );
  }

  void _navigateToSignUp() async {
    // Save invite code early — survives PKCE redirect
    await PendingInvite.save(widget.inviteCode);

    // If inviter was found, go to dedicated sign-up page
    if (_inviter != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InviteSignUpScreen(
            inviteCode: widget.inviteCode,
            inviter: _inviter!,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
