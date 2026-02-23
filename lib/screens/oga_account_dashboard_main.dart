import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oga_character.dart';
import '../widgets/character_card.dart';
import 'character_detail_screen.dart';
import 'settings/settings_modal.dart';
import 'tabs/friends_tab.dart';
import 'tabs/about_tab.dart';
import 'faq_page.dart';
import 'contact_modal.dart';
import 'share_profile_screen.dart';

class OGAAccountDashboard extends StatefulWidget {
  final String? sessionId;
  final String? acquiredCharacterId;

  const OGAAccountDashboard({
    super.key,
    this.sessionId,
    this.acquiredCharacterId,
  });

  @override
  State<OGAAccountDashboard> createState() => _OGAAccountDashboardState();
}

class _OGAAccountDashboardState extends State<OGAAccountDashboard> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _ownedCharacterId;
  String? _avatarUrl;
  String _currentTab = 'PROFILE';
  DateTime? _joinedDate;
  bool _isGridView = true;
  final _pageController = PageController();

  // V2 Brand Colors (Heimdal Aesthetic)
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  static const List<String> _tabs = ['PROFILE', 'FRIENDS', 'ABOUT'];
  static const _months = [
    '',
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

  // ─── Character list (no doubling) ─────────────────────────
  List<OGACharacter> get _characters => getAllCharactersSorted();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('\u26a0\ufe0f No authenticated user');
        setState(() {
          _ownedCharacterId = widget.acquiredCharacterId ?? 'ryu';
          _isLoading = false;
        });
        return;
      }

      _joinedDate = DateTime.tryParse(user.createdAt);

      final response = await supabase
          .from('profiles')
          .select()
          .eq('email', user.email!)
          .maybeSingle();

      if (response != null) {
        if (_joinedDate == null && response['created_at'] != null) {
          _joinedDate = DateTime.tryParse(response['created_at'].toString());
        }
        setState(() {
          _userData = response;
          _ownedCharacterId =
              widget.acquiredCharacterId ??
              response['starter_character'] ??
              'ryu';
          _avatarUrl = response['avatar_url'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _ownedCharacterId = widget.acquiredCharacterId ?? 'ryu';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('\u274c Error loading user data: $e');
      setState(() {
        _ownedCharacterId = widget.acquiredCharacterId ?? 'ryu';
        _isLoading = false;
      });
    }
  }

  String get _joinedText {
    if (_joinedDate == null) return '';
    return 'Joined ${_months[_joinedDate!.month]} ${_joinedDate!.year}';
  }

  /// Returns a display-safe name, never showing raw email.
  String get _displayName {
    final firstName = _userData?['first_name'] ?? '';
    final lastName = _userData?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    final storedName = _userData?['full_name'] ?? '';
    if (storedName.isNotEmpty && !storedName.contains('@')) return storedName;

    return 'Player';
  }

  /// Returns a display-safe username.
  String get _displayUsername {
    final username = _userData?['username']?.toString() ?? '';
    if (username.isNotEmpty) return username;

    final name = _displayName;
    if (name != 'Player') return name.toLowerCase().replaceAll(' ', '');

    return 'player';
  }

  // ─── Character access (uses model compat getters) ──────────

  OGACharacter get _ownedCharacter => OGACharacter.fromId(_ownedCharacterId);

  // ─── Navigation helpers ───────────────────────────────────

  void _openSettings() {
    SettingsModal.show(
      context,
      userData: _userData,
      avatarImagePath: _ownedCharacter.heroImage,
      onProfileUpdated: _loadUserData,
    );
  }

  void _openShareProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareProfileScreen(
          inviteCode: _userData?['invite_code'] as String?,
          displayName: _displayName,
        ),
      ),
    );
  }

  void _handleLogout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: voidBlack,
        body: Center(child: CircularProgressIndicator(color: neonGreen)),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: voidBlack,
        appBar: _buildAppBar(isMobile),
        drawer: isMobile ? _buildMobileDrawer() : null,
        body: _buildBody(isMobile),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentTab = _tabs[index]);
      },
      children: [
        // Tab 0: PROFILE
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(isMobile)),
            SliverToBoxAdapter(child: _buildSectionHeader(isMobile)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
              sliver: _isGridView
                  ? _buildCharacterGrid(isMobile)
                  : _buildCharacterList(isMobile),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
        // Tab 1: FRIENDS
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(isMobile)),
            const FriendsTab(),
          ],
        ),
        // Tab 2: ABOUT
        const CustomScrollView(slivers: [AboutTab()]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: voidBlack,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      title: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: isMobile ? 22 : 28,
              errorBuilder: (_, _, _) => const Text(
                'OGA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: isMobile
                  ? Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    )
                  : _buildNavPill(),
            ),
            Positioned(right: 0, child: _buildActionIcons(isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavPill() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ironGrey, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _tabs.map((t) => _buildNavTab(t)).toList(),
      ),
    );
  }

  Widget _buildNavTab(String label) {
    final isActive = _currentTab == label;
    return GestureDetector(
      onTap: () {
        final index = _tabs.indexOf(label);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? voidBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [if (!isMobile) _buildAvatarDropdown()],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AVATAR DROPDOWN
  // ═══════════════════════════════════════════════════════════

  Widget _buildAvatarDropdown() {
    final userName = _displayName;
    final email = supabase.auth.currentUser?.email ?? '';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: deepCharcoal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ironGrey.withValues(alpha: 0.5)),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            break;
          case 'settings':
            _openSettings();
            break;
          case 'about':
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            break;
          case 'faq':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqPage()),
            );
            break;
          case 'contact':
            ContactModal.show(context);
            break;
          case 'logout':
            _handleLogout();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _buildAvatarCircle(20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        _dropItem('profile', 'My Profile'),
        _dropItem('settings', 'Settings'),
        _dropItem('about', 'About OGA'),
        _dropItem('faq', 'FAQ'),
        _dropItem('contact', 'Contact'),
        const PopupMenuDivider(height: 1),
        _dropItem('logout', 'Log out', dimmed: true),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarCircle(12),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  PopupMenuItem<String> _dropItem(String v, String l, {bool dimmed = false}) {
    return PopupMenuItem<String>(
      value: v,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        l,
        style: TextStyle(
          color: dimmed
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Builds a circular avatar using network URL if available,
  /// falling back to character asset image.
  Widget _buildAvatarCircle(double radius) {
    final ownedChar = _ownedCharacter;
    final color = ownedChar.cardColor;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: ClipOval(
        child: _avatarUrl != null
            ? Image.network(
                _avatarUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                errorBuilder: (_, _, _) => _assetAvatar(ownedChar, radius),
              )
            : _assetAvatar(ownedChar, radius),
      ),
    );
  }

  Widget _assetAvatar(OGACharacter char, double radius) {
    return Image.asset(
      char.heroImage,
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
      errorBuilder: (_, _, _) =>
          Icon(Icons.person, color: Colors.white, size: radius),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE DRAWER
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: deepCharcoal,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: voidBlack),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                height: 40,
                errorBuilder: (_, _, _) => const Text(
                  'OGA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          ...[
            ('PROFILE', Icons.person_outline),
            ('FRIENDS', Icons.people_outline),
            ('ABOUT', Icons.info_outline),
          ].map((item) => _drawerTab(item.$1, item.$2)),
          const Divider(color: ironGrey, height: 32),
          _drawerAction('SETTINGS', Icons.settings_outlined, () {
            Navigator.pop(context);
            _openSettings();
          }),
          _drawerAction('FAQ', Icons.help_outline, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqPage()),
            );
          }),
          _drawerAction('CONTACT', Icons.mail_outline, () {
            Navigator.pop(context);
            ContactModal.show(context);
          }),
          const Spacer(),
          _drawerAction('LOG OUT', Icons.logout, () {
            Navigator.pop(context);
            _handleLogout();
          }),
          const Divider(color: ironGrey),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ONE EARTH RISING\u2122',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTab(String label, IconData icon) {
    final isActive = _currentTab == label;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? neonGreen : Colors.white54,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
      tileColor: isActive ? neonGreen.withValues(alpha: 0.05) : null,
      onTap: () {
        final index = _tabs.indexOf(label);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        Navigator.pop(context);
      },
    );
  }

  Widget _drawerAction(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
      onTap: onTap,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroSection(bool isMobile) {
    final displayName = _displayName;
    final username = _displayUsername;
    final ownedChar = _ownedCharacter;
    final charColor = ownedChar.cardColor;
    final glowColor = ownedChar.glowColor;

    return Stack(
      children: [
        Container(
          height: isMobile ? 380 : 420,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/heroes/hero.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              onError: (_, _e) {},
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
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
        Positioned(
          left: isMobile ? 20 : 60,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: charColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _avatarUrl != null
                      ? Image.network(
                          _avatarUrl!,
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _heroAssetAvatar(ownedChar),
                        )
                      : _heroAssetAvatar(ownedChar),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 28 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '@${username.toUpperCase()}',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              if (_joinedText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _joinedText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  GestureDetector(
                    onTap: _openSettings,
                    child: _heroBtn('SETTINGS'),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openShareProfile,
                    child: _heroBtn('SHARE PROFILE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroAssetAvatar(OGACharacter char) {
    return Image.asset(
      char.heroImage,
      height: 70,
      width: 70,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 70,
        width: 70,
        color: deepCharcoal,
        child: const Icon(Icons.person, color: Colors.white38, size: 32),
      ),
    );
  }

  Widget _heroBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ironGrey),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION HEADER + CHARACTER VIEWS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 20,
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
          const Text(
            'MY LIBRARY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_characters.length} CHARACTERS',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
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

  // ─── GRID VIEW ────────────────────────────────────────────

  Widget _buildCharacterGrid(bool isMobile) {
    final chars = _characters;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final ch = chars[index];
        return GestureDetector(
          onTap: () => _openDetail(ch),
          child: CharacterCard(
            character: ch,
            isOwned: ch.isOwned,
            progress: ch.progress,
          ),
        );
      }, childCount: chars.length),
    );
  }

  // ─── LIST VIEW ────────────────────────────────────────────

  Widget _buildCharacterList(bool isMobile) {
    final chars = _characters;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ch = chars[index];
        final charColor = ch.cardColor;

        return GestureDetector(
          onTap: () => _openDetail(ch),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ch.isOwned
                    ? ch.glowColor.withValues(alpha: 0.4)
                    : ironGrey.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Character image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    ch.thumbnailImage.isNotEmpty
                        ? ch.thumbnailImage
                        : ch.heroImage,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 56,
                      height: 56,
                      color: charColor,
                      child: const Icon(Icons.person, color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + IP
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

                // Progress ring or lock
                if (ch.isOwned) ...[
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: ch.progress,
                          strokeWidth: 2.5,
                          color: neonGreen,
                          backgroundColor: ironGrey,
                        ),
                        Text(
                          '${(ch.progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: neonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.lock_outline,
                    color: Colors.white.withValues(alpha: 0.15),
                    size: 20,
                  ),
                ],

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
      }, childCount: chars.length),
    );
  }

  // ─── DETAIL NAVIGATION ────────────────────────────────────

  void _openDetail(OGACharacter ch) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, anim, secondAnim) =>
            CharacterDetailScreen(character: ch, isOwned: ch.isOwned),
        transitionsBuilder: (_, anim, secondAnim, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
  }
}
