import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  OGACharacter? _heroCharacter;
  String _currentTab = 'ACCOUNT';

  // OGA Brand Standards
  static const Color ogaGreen = Color(0xFF00C806);
  static const Color ogaBlack = Color(0xFF000000);
  static const Color ogaSurface = Color(0xFF0A0A0A);
  static const Color ogaCardBg = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (widget.sessionId != null) {
        final response = await supabase
            .from('profiles')
            .select()
            .eq('session_id', widget.sessionId!)
            .single();

        setState(() {
          _userData = response;
          final characterId =
              widget.acquiredCharacterId ?? response['starter_character'];
          _heroCharacter = OGACharacter.allCharacters.firstWhere(
            (char) => char.id == characterId,
            orElse: () => OGACharacter.allCharacters.first,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _heroCharacter = OGACharacter.allCharacters.first;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ogaBlack,
        body: Center(child: CircularProgressIndicator(color: ogaGreen)),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: ogaBlack,
      appBar: _buildFigmaAppBar(isMobile),
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildFigmaHero(isMobile)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 20,
            ),
            sliver: _buildCharacterGrid(isMobile),
          ),
          if (isMobile) SliverToBoxAdapter(child: _buildFigmaFooter()),
        ],
      ),
    );
  }

  /// Mobile-specific footer following Figma 9:00:24 PM design
  Widget _buildFigmaFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Navigation
          _footerNavLink("PORTAL PASSES"),
          _footerNavLink("MY LIBRARY"),
          _footerNavLink("MARKETPLACE"),
          _footerNavLink("ACTIVITY"),
          _footerNavLink("CONTACTS"),
          _footerNavLink("ABOUT"),
          const SizedBox(height: 48),

          // Legal Subsection
          const Text(
            "LEGAL",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _footerLegalLink("TERMS OF SERVICE"),
          _footerLegalLink("PRIVACY POLICY"),
          _footerLegalLink("LEGAL"),
          _footerLegalLink("LPR POLICY"),
          const SizedBox(height: 64),

          // Large Brand Logo
          Center(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset('assets/logo.png', width: 280),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              "ogahub.com",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerNavLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _footerLegalLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace', // Matches the "code" style in Figma
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFigmaAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: ogaBlack,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Centered OGA Logo
            Image.asset('assets/logo.png', height: isMobile ? 22 : 28),

            // 2. Left-aligned Navigation (Desktop Only)
            if (!isMobile)
              Positioned(
                left: 0,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavTab('ACCOUNT'),
                      _buildNavTab('PROFILE'),
                      _buildNavTab('FRIENDS'),
                      _buildNavTab('ABOUT'),
                    ],
                  ),
                ),
              ),

            // 3. Right-aligned Actions
            Positioned(right: 0, child: _buildActionIcons(isMobile)),

            // 4. Hamburger for Mobile
            if (isMobile)
              Positioned(
                left: 0,
                child: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(String label) {
    bool isActive = _currentTab == label;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
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
        const Icon(Icons.north_east, color: ogaGreen, size: 18),
        const SizedBox(width: 12),
        const Icon(Icons.bolt, color: Colors.white, size: 18),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 12,
            backgroundColor: ogaGreen,
            child: ClipOval(
              child: Image.asset('assets/characters/guggimon.png'),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
        ],
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: ogaSurface,
      child: Column(
        children: [
          DrawerHeader(child: Image.asset('assets/logo.png', height: 40)),
          _buildDrawerItem('ACCOUNT', Icons.account_circle),
          _buildDrawerItem('PROFILE', Icons.person),
          _buildDrawerItem('FRIENDS', Icons.people),
          _buildDrawerItem('ABOUT', Icons.info),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        setState(() => _currentTab = label);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFigmaHero(bool isMobile) {
    final userName = _userData?['full_name'] ?? 'NKNIGHT';
    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/heroes/hero.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                ogaBlack.withValues(alpha: 0.8),
                ogaBlack,
              ],
            ),
          ),
        ),
        Positioned(
          left: isMobile ? 20 : 60,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(height: 15),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '@${userName.toLowerCase().replaceAll(' ', '')}',
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildHeroButton("SETTINGS", false),
                  const SizedBox(width: 10),
                  _buildHeroButton("SHARE PROFILE", false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/characters/guggimon.png',
          height: 70,
          width: 70,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeroButton(String label, bool primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primary ? ogaGreen : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCharacterGrid(bool isMobile) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 5,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final char = OGACharacter
            .allCharacters[index % OGACharacter.allCharacters.length];
        return _buildCharacterCard(char);
      }, childCount: 8),
    );
  }

  Widget _buildCharacterCard(OGACharacter char) {
    return Container(
      decoration: BoxDecoration(
        color: ogaSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: Image.asset(
                    char.imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.more_horiz, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      char.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      char.subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                _buildProgressRing(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing() {
    return SizedBox(
      height: 30,
      width: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(
            value: 0.99,
            strokeWidth: 2,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(ogaGreen),
          ),
          const Text(
            "99%",
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OGACharacter {
  final String id;
  final String name;
  final String subtitle;
  final String imagePath;
  final Color glowColor;

  const OGACharacter({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imagePath,
    required this.glowColor,
  });

  static const ryu = OGACharacter(
    id: 'ryu',
    name: 'RYU',
    subtitle: 'Street Fighter',
    imagePath: 'assets/characters/ryu.png',
    glowColor: Color(0xFFEF4444),
  );
  static const vegeta = OGACharacter(
    id: 'vegeta',
    name: 'VEGETA',
    subtitle: 'Dragon Ball Z',
    imagePath: 'assets/characters/vegeta.png',
    glowColor: Color(0xFF3B82F6),
  );
  static const guggimon = OGACharacter(
    id: 'guggimon',
    name: 'GUGGIMON',
    subtitle: 'Super Plastic',
    imagePath: 'assets/characters/guggimon.png',
    glowColor: Color(0xFFF97316),
  );
  static const allCharacters = [ryu, vegeta, guggimon];
}
