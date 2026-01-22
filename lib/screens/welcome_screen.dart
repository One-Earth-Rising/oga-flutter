import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// OGA Character Acquisition Welcome Screen
/// Shows the acquired character after onboarding completion
class WelcomeScreen extends StatefulWidget {
  final String sessionId;

  const WelcomeScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  Map<String, dynamic>? _userData;
  OGACharacter? _assignedCharacter;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final supabase = Supabase.instance.client;

  // OGA Brand Colors - UPDATED GREEN
  static const Color ogaGreen = Color(0xFF00C806); // Updated to match Figma
  static const Color ogaBlack = Color(0xFF0C0C0C);
  static const Color ogaSurface = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserDataAndAssignCharacter();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  Future<void> _loadUserDataAndAssignCharacter() async {
    try {
      print('🔍 Fetching user data for session: ${widget.sessionId}');

      final response = await supabase
          .from('profiles')
          .select()
          .eq('session_id', widget.sessionId)
          .single();

      print('✅ User data loaded: ${response['full_name']}');

      setState(() {
        _userData = response;
      });

      final character = _determineCharacter(
        gameGenre: response['game_genre'],
        gameStyle: response['game_style'],
        favoriteGame: response['favorite_game'],
      );

      print('🎮 Assigned character: ${character.name}');

      await supabase
          .from('profiles')
          .update({
            'starter_character': character.id,
            'character_acquired_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', widget.sessionId);

      setState(() {
        _assignedCharacter = character;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('❌ Error loading character: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  OGACharacter _determineCharacter({
    String? gameGenre,
    String? gameStyle,
    String? favoriteGame,
  }) {
    final genre = (gameGenre ?? '').toLowerCase();
    final style = (gameStyle ?? '').toLowerCase();
    final favorite = (favoriteGame ?? '').toLowerCase();

    print(
      '🎯 Matching character: genre=$genre, style=$style, favorite=$favorite',
    );

    for (final character in OGACharacter.allCharacters) {
      if (character.genres.any(
        (g) => genre.contains(g) || style.contains(g) || favorite.contains(g),
      )) {
        return character;
      }
    }

    if (favorite.contains('street fighter') || favorite.contains('fighting')) {
      return OGACharacter.ryu;
    }
    if (favorite.contains('dragon ball') || favorite.contains('dbz')) {
      return OGACharacter.vegeta;
    }
    if (favorite.contains('mario')) {
      return OGACharacter.mario;
    }
    if (favorite.contains('sonic')) {
      return OGACharacter.sonic;
    }
    if (favorite.contains('zelda') || favorite.contains('link')) {
      return OGACharacter.link;
    }
    if (favorite.contains('digimon') || favorite.contains('pokemon')) {
      return OGACharacter.guggimon;
    }

    return OGACharacter.ryu;
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed(
      '/dashboard',
      arguments: {
        'sessionId': widget.sessionId,
        'character': _assignedCharacter?.id,
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ogaBlack,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingScreen()
            : _hasError
            ? _buildErrorScreen()
            : _buildAcquisitionScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ogaGreen),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your character...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Character',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ogaGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'GO BACK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcquisitionScreen() {
    if (_assignedCharacter == null) return const SizedBox();

    final character = _assignedCharacter!;
    final userName = _userData?['full_name'] ?? 'Friend';
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing - everything fits above the fold
    final isMobile = screenWidth < 600;
    final imageSize = isMobile
        ? screenWidth *
              0.5 // 50% of screen width on mobile (smaller)
        : screenHeight * 0.35; // 35% of screen height on web

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24.0 : 48.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome message
                Text(
                  'Welcome, $userName!',
                  style: TextStyle(
                    color: ogaGreen,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // "YOU HAVE ACQUIRED" title
                Text(
                  'YOU HAVE ACQUIRED',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Character image with glow - SMALLER SIZE
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: character.glowColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(character.imagePath, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Character name
                Text(
                  character.name,
                  style: TextStyle(
                    color: ogaGreen,
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Character subtitle
                Text(
                  character.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isMobile ? 12 : 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Character description - COMPACT
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 40),
                  child: Text(
                    character.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: isMobile ? 12 : 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 32),

                // "DISCOVER" button - SMALLER, GREENER
                SizedBox(
                  width: isMobile ? double.infinity : 300,
                  child: ElevatedButton(
                    onPressed: _navigateToDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ogaGreen, // New green: #00C806
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                      shadowColor: ogaGreen.withOpacity(0.5),
                    ),
                    child: Text(
                      'DISCOVER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// OGA Character Model
class OGACharacter {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String imagePath;
  final Color glowColor;
  final List<String> genres;

  const OGACharacter({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.glowColor,
    required this.genres,
  });

  static const ryu = OGACharacter(
    id: 'ryu',
    name: 'RYU',
    subtitle: 'Street Fighter',
    description:
        'A disciplined martial artist seeking true strength. Ryu is a master of Ansatsuken, wielding powerful strikes and legendary techniques.',
    imagePath: 'assets/characters/ryu.png',
    glowColor: Color(0xFFEF4444),
    genres: ['fighting', 'action', 'arcade'],
  );

  static const vegeta = OGACharacter(
    id: 'vegeta',
    name: 'VEGETA',
    subtitle: 'Dragon Ball',
    description:
        'The proud Saiyan Prince driven by an intense desire to surpass all others. His combat prowess is legendary with devastating energy attacks.',
    imagePath: 'assets/characters/vegeta.png',
    glowColor: Color(0xFF3B82F6),
    genres: ['action', 'rpg', 'adventure'],
  );

  static const guggimon = OGACharacter(
    id: 'guggimon',
    name: 'GUGGIMON',
    subtitle: 'Superplastic',
    description:
        'A rebellious character with attitude and style. Guggimon represents creativity, mischief, and breaking the rules in the most fun way possible.',
    imagePath: 'assets/characters/guggimon.png',
    glowColor: Color(0xFFF97316),
    genres: ['rpg', 'strategy', 'simulation'],
  );

  static const mario = OGACharacter(
    id: 'mario',
    name: 'MARIO',
    subtitle: 'Super Mario',
    description:
        'The legendary plumber hero of the Mushroom Kingdom. Known for his jumping prowess and never-give-up attitude in saving Princess Peach.',
    imagePath: 'assets/characters/mario.png',
    glowColor: Color(0xFFEF4444),
    genres: ['platformer', 'casual', 'adventure'],
  );

  static const sonic = OGACharacter(
    id: 'sonic',
    name: 'SONIC',
    subtitle: 'Sonic the Hedgehog',
    description:
        'The fastest hedgehog alive, Sonic races through levels at supersonic speeds. His attitude and speed make him an unstoppable force.',
    imagePath: 'assets/characters/sonic.png',
    glowColor: Color(0xFF3B82F6),
    genres: ['platformer', 'racing', 'action'],
  );

  static const link = OGACharacter(
    id: 'link',
    name: 'LINK',
    subtitle: 'The Legend of Zelda',
    description:
        'The courageous hero of Hyrule destined to defeat evil. Armed with the Master Sword and Hylian Shield, Link embarks on epic quests.',
    imagePath: 'assets/characters/link.png',
    glowColor: Color(0xFF10B981),
    genres: ['adventure', 'rpg', 'puzzle'],
  );

  static const allCharacters = [ryu, vegeta, guggimon, mario, sonic, link];
}
