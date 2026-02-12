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
  String _currentTab = 'PROFILE';
  DateTime? _joinedDate;

  // V2 Brand Colors (Heimdal Aesthetic)
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  static const List<String> _tabs = ['PROFILE', 'FRIENDS', 'ABOUT'];

  // Month names for joined date display
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

      // Get joined date from auth user metadata
      _joinedDate = user.createdAt != null
          ? DateTime.tryParse(user.createdAt)
          : null;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('email', user.email!)
          .maybeSingle();

      if (response != null) {
        // Also try to get joined date from profile if available
        if (_joinedDate == null && response['created_at'] != null) {
          _joinedDate = DateTime.tryParse(response['created_at'].toString());
        }
        setState(() {
          _userData = response;
          _ownedCharacterId =
              widget.acquiredCharacterId ??
              response['starter_character'] ??
              'ryu';
          _isLoading = false;
        });
      } else {
        debugPrint('\u26a0\ufe0f No profile found for ${user.email}');
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

  void _openSettings() {
    final ownedChar = OGACharacter.fromId(_ownedCharacterId);
    SettingsModal.show(
      context,
      userData: _userData,
      avatarImagePath: ownedChar.imagePath,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: voidBlack,
        body: Center(child: CircularProgressIndicator(color: neonGreen)),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: voidBlack,
      appBar: _buildAppBar(isMobile),
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: _buildBody(isMobile),
    );
  }

  Widget _buildBody(bool isMobile) {
    switch (_currentTab) {
      case 'FRIENDS':
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(isMobile)),
            const FriendsTab(),
          ],
        );
      case 'ABOUT':
        return CustomScrollView(slivers: [const AboutTab()]);
      case 'PROFILE':
      default:
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(isMobile)),
            SliverToBoxAdapter(child: _buildSectionHeader(isMobile)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
              sliver: _buildCharacterGrid(isMobile),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        );
    }
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
              errorBuilder: (_, __, ___) => const Text(
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
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
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
        children: _tabs.map((tab) => _buildNavTab(tab)).toList(),
      ),
    );
  }

  Widget _buildNavTab(String label) {
    final isActive = _currentTab == label;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = label),
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
      children: [
        const Icon(Icons.north_east, color: neonGreen, size: 18),
        const SizedBox(width: 12),
        const Icon(Icons.bolt, color: Colors.white, size: 18),
        if (!isMobile) ...[const SizedBox(width: 12), _buildAvatarDropdown()],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AVATAR DROPDOWN
  // ═══════════════════════════════════════════════════════════

  Widget _buildAvatarDropdown() {
    final owned = OGACharacter.fromId(_ownedCharacterId);
    final userName = _userData?['full_name'] ?? 'Player';
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
            setState(() => _currentTab = 'PROFILE');
            break;
          case 'settings':
            _openSettings();
            break;
          case 'about':
            setState(() => _currentTab = 'ABOUT');
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
      itemBuilder: (context) => [
        // User info header
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: owned.cardColor,
                child: ClipOval(
                  child: Image.asset(
                    owned.imagePath,
                    fit: BoxFit.cover,
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                ),
              ),
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
        _buildDropdownItem('profile', 'My Profile'),
        _buildDropdownItem('settings', 'Settings'),
        _buildDropdownItem('about', 'About OGA'),
        _buildDropdownItem('faq', 'FAQ'),
        _buildDropdownItem('contact', 'Contact'),
        const PopupMenuDivider(height: 1),
        _buildDropdownItem('logout', 'Log out', dimmed: true),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: owned.cardColor,
            child: ClipOval(
              child: Image.asset(
                owned.imagePath,
                fit: BoxFit.cover,
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 14),
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildDropdownItem(
    String value,
    String label, {
    bool dimmed = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label,
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
                errorBuilder: (_, __, ___) => const Text(
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
          // Nav tabs
          ...[
            ('PROFILE', Icons.person_outline),
            ('FRIENDS', Icons.people_outline),
            ('ABOUT', Icons.info_outline),
          ].map((item) => _buildDrawerItem(item.$1, item.$2)),

          const Divider(color: ironGrey, height: 32),

          // Extra items (matching dropdown)
          _buildDrawerAction('SETTINGS', Icons.settings_outlined, () {
            Navigator.pop(context);
            _openSettings();
          }),
          _buildDrawerAction('FAQ', Icons.help_outline, () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqPage()),
            );
          }),
          _buildDrawerAction('CONTACT', Icons.mail_outline, () {
            Navigator.pop(context);
            ContactModal.show(context);
          }),

          const Spacer(),

          // Log out
          _buildDrawerAction('LOG OUT', Icons.logout, () {
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

  Widget _buildDrawerItem(String label, IconData icon) {
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
        setState(() => _currentTab = label);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDrawerAction(String label, IconData icon, VoidCallback onTap) {
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
    final userName = _userData?['full_name'] ?? 'PLAYER';
    final ownedChar = OGACharacter.fromId(_ownedCharacterId);

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
                  color: ownedChar.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: ownedChar.glowColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    ownedChar.imagePath,
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 70,
                      width: 70,
                      color: deepCharcoal,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white38,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Username
              Text(
                userName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 28 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              // Handle
              Text(
                '@${userName.toUpperCase().replaceAll(' ', '')}',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),

              // Joined date
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

              // Action buttons
              Row(
                children: [
                  GestureDetector(
                    onTap: _openSettings,
                    child: _buildHeroButton('SETTINGS', false),
                  ),
                  const SizedBox(width: 10),
                  _buildHeroButton('SHARE PROFILE', false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroButton(String label, bool primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primary ? neonGreen : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primary ? neonGreen : ironGrey, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? Colors.black : Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION HEADER + CHARACTER GRID (PROFILE tab)
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
            '${OGACharacter.allCharacters.length} CHARACTERS',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ironGrey, width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_view, color: Colors.white54, size: 14),
                SizedBox(width: 6),
                Icon(Icons.view_list, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterGrid(bool isMobile) {
    final characters = OGACharacter.allCharacters;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final charIndex = index % characters.length;
        final character = characters[charIndex];
        final isOwned =
            index < characters.length && character.id == _ownedCharacterId;

        return CharacterCard(
          character: character,
          isOwned: isOwned,
          progress: isOwned ? 0.99 : 0.0,
          onTap: () => _openCharacterDetail(character, isOwned),
        );
      }, childCount: characters.length * 2),
    );
  }

  void _openCharacterDetail(OGACharacter character, bool isOwned) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return CharacterDetailScreen(character: character, isOwned: isOwned);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
