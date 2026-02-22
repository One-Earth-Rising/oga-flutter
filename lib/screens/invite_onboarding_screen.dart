import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile setup screen shown after invite signup flow.
/// 3-step onboarding: Identity → Pick Starter → Preferences
///
/// Flow: Confirm → InviteOnboardingScreen → Dashboard
///
/// Data captured:
/// - Step 1: first_name, last_name, username, full_name
/// - Step 2: starter_character
/// - Step 3: preferred_genres, preferred_platforms, role
class InviteOnboardingScreen extends StatefulWidget {
  const InviteOnboardingScreen({super.key});

  @override
  State<InviteOnboardingScreen> createState() => _InviteOnboardingScreenState();
}

class _InviteOnboardingScreenState extends State<InviteOnboardingScreen>
    with SingleTickerProviderStateMixin {
  // ─── Brand Colors ─────────────────────────────────────────
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  // ─── State ────────────────────────────────────────────────
  int _currentStep = 0; // 0=Identity, 1=Character, 2=Preferences

  // Step 1: Identity
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _usernameError;

  // Step 2: Character
  String? _selectedCharacter;

  // Step 3: Preferences
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedPlatforms = {};

  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ─── Character Data ───────────────────────────────────────
  static const List<Map<String, dynamic>> _characters = [
    {
      'id': 'ryu',
      'name': 'RYU',
      'ip': 'Street Fighter',
      'color': Color(0xFFDC2626),
      'image': 'assets/images/characters/ryu_main.png',
      'description': 'The Eternal Warrior',
    },
    {
      'id': 'vegeta',
      'name': 'VEGETA',
      'ip': 'Dragon Ball Z',
      'color': Color(0xFF2563EB),
      'image': 'assets/images/characters/vegeta_main.png',
      'description': 'The Saiyan Prince',
    },
    {
      'id': 'guggimon',
      'name': 'GUGGIMON',
      'ip': 'Superplastic',
      'color': Color(0xFF7C3AED),
      'image': 'assets/images/characters/guggimon_main.png',
      'description': 'The Fashion Horror',
    },
  ];

  // ─── Genre & Platform Options ─────────────────────────────
  static const List<String> _genres = [
    'FPS',
    'RPG',
    'Fighting',
    'Roguelike',
    'Strategy',
    'Battle Royale',
    'Cozy / Indie',
  ];

  static const List<String> _platforms = [
    'PlayStation',
    'Xbox',
    'PC',
    'Switch',
    'Mobile',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Step Transition ──────────────────────────────────────
  void _goToStep(int step) {
    _animController.reset();
    setState(() => _currentStep = step);
    _animController.forward();
  }

  // ─── Save All Data ────────────────────────────────────────
  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim().toLowerCase();
      final fullName = '$firstName $lastName'.trim();

      final updates = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName.isNotEmpty ? fullName : null,
        'role': 'Gamer',
        'interested_in_collectibles': 'Yes, that\'s sick',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Username (if provided)
      if (username.isNotEmpty) {
        updates['username'] = username;
      }

      // Starter character
      if (_selectedCharacter != null) {
        updates['starter_character'] = _selectedCharacter;
      }

      // Genres
      if (_selectedGenres.isNotEmpty) {
        updates['preferred_genres'] = _selectedGenres.join(', ');
      }

      // Platforms
      if (_selectedPlatforms.isNotEmpty) {
        updates['preferred_platforms'] = _selectedPlatforms.join(', ');
      }

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('email', user.email!);

      debugPrint('✅ Onboarding complete: $fullName, char=$_selectedCharacter');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      debugPrint('❌ Error saving onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: voidBlack,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Progress bar
              _buildProgressBar(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Progress Bar ─────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            // Step indicators
            Row(
              children: List.generate(3, (i) {
                final isActive = i <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? neonGreen : ironGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            // Step label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _stepLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${_currentStep + 1} / 3',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _stepLabel {
    switch (_currentStep) {
      case 0:
        return 'YOUR IDENTITY';
      case 1:
        return 'PICK YOUR STARTER';
      case 2:
        return 'YOUR STYLE';
      default:
        return '';
    }
  }

  // ─── Step Router ──────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep();
      case 1:
        return _buildCharacterStep();
      case 2:
        return _buildPreferencesStep();
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 1: IDENTITY
  // ═══════════════════════════════════════════════════════════

  Widget _buildIdentityStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Icon
          _buildStepIcon(Icons.person_outline),
          const SizedBox(height: 24),

          const Text(
            'SET UP YOUR PROFILE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us who you are, Agent.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 36),

          _buildTextField(
            controller: _firstNameController,
            label: 'FIRST NAME',
            hint: 'Enter your first name',
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'First name is required';
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _lastNameController,
            label: 'LAST NAME',
            hint: 'Enter your last name',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Last name is required';
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _usernameController,
            label: 'USERNAME',
            hint: 'Choose a username',
            prefix: '@',
            errorText: _usernameError,
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                if (v.trim().length < 3) return 'Min 3 characters';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                  return 'Letters, numbers, and underscores only';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Optional — you can set this later in Settings',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // Continue button
          _buildPrimaryButton(
            label: 'CONTINUE',
            onTap: () async {
              if (!_formKey.currentState!.validate()) return;

              // Check username uniqueness
              final username = _usernameController.text.trim().toLowerCase();
              if (username.isNotEmpty) {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  final existing = await Supabase.instance.client
                      .from('profiles')
                      .select('email')
                      .eq('username', username)
                      .neq('email', user.email!)
                      .maybeSingle();

                  if (existing != null) {
                    setState(() => _usernameError = 'Username already taken');
                    return;
                  }
                }
              }

              _goToStep(1);
            },
          ),

          const SizedBox(height: 12),
          _buildSkipButton(onTap: () => _goToStep(1)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 2: PICK YOUR STARTER
  // ═══════════════════════════════════════════════════════════

  Widget _buildCharacterStep() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        const SizedBox(height: 32),

        _buildStepIcon(Icons.shield_outlined),
        const SizedBox(height: 24),

        const Text(
          'PICK YOUR STARTER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your first character. More will follow.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),

        const SizedBox(height: 32),

        // Character cards
        isMobile
            ? Column(
                children: _characters
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCharacterCard(c),
                      ),
                    )
                    .toList(),
              )
            : Row(
                children: _characters
                    .map(
                      (c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildCharacterCard(c),
                        ),
                      ),
                    )
                    .toList(),
              ),

        const SizedBox(height: 36),

        _buildPrimaryButton(
          label: 'CONTINUE',
          onTap: _selectedCharacter != null ? () => _goToStep(2) : null,
        ),

        const SizedBox(height: 12),
        _buildSkipButton(onTap: () => _goToStep(2)),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCharacterCard(Map<String, dynamic> character) {
    final id = character['id'] as String;
    final name = character['name'] as String;
    final ip = character['ip'] as String;
    final color = character['color'] as Color;
    final description = character['description'] as String;
    final imagePath = character['image'] as String;
    final isSelected = _selectedCharacter == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedCharacter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? neonGreen : ironGrey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: neonGreen.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              // Character image area
              AspectRatio(
                aspectRatio: MediaQuery.of(context).size.width < 600
                    ? 2.5
                    : 0.85,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient using character color
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color.withOpacity(0.3), deepCharcoal],
                        ),
                      ),
                    ),
                    // Character image
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.person,
                          color: color.withOpacity(0.5),
                          size: 48,
                        ),
                      ),
                    ),
                    // Selected checkmark
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: neonGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        ip,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 3: PREFERENCES
  // ═══════════════════════════════════════════════════════════

  Widget _buildPreferencesStep() {
    return Column(
      children: [
        const SizedBox(height: 32),

        _buildStepIcon(Icons.sports_esports_outlined),
        const SizedBox(height: 24),

        const Text(
          'YOUR STYLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help us personalize your experience.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),

        const SizedBox(height: 32),

        // Genre section
        _buildChipSection(
          label: 'FAVORITE GENRES',
          options: _genres,
          selected: _selectedGenres,
          onToggle: (genre) {
            setState(() {
              if (_selectedGenres.contains(genre)) {
                _selectedGenres.remove(genre);
              } else {
                _selectedGenres.add(genre);
              }
            });
          },
        ),

        const SizedBox(height: 28),

        // Platform section
        _buildChipSection(
          label: 'YOUR PLATFORMS',
          options: _platforms,
          selected: _selectedPlatforms,
          onToggle: (platform) {
            setState(() {
              if (_selectedPlatforms.contains(platform)) {
                _selectedPlatforms.remove(platform);
              } else {
                _selectedPlatforms.add(platform);
              }
            });
          },
        ),

        const SizedBox(height: 36),

        _buildPrimaryButton(
          label: 'ENTER MY LIBRARY',
          icon: Icons.arrow_forward,
          onTap: _isSaving ? null : _saveAndFinish,
          isLoading: _isSaving,
        ),

        const SizedBox(height: 12),
        _buildSkipButton(
          label: 'Skip — I\'ll set this later',
          onTap: _isSaving ? null : _saveAndFinish,
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildChipSection({
    required String label,
    required List<String> options,
    required Set<String> selected,
    required void Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () => onToggle(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? neonGreen.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? neonGreen : ironGrey,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? neonGreen : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════

  Widget _buildStepIcon(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: neonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonGreen.withOpacity(0.3)),
      ),
      child: Icon(icon, color: neonGreen, size: 32),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isEnabled ? neonGreen : neonGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isEnabled ? Colors.black : Colors.black45,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.black, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSkipButton({String? label, VoidCallback? onTap}) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label ?? 'Skip for now',
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    String? errorText,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.redAccent),
            filled: true,
            fillColor: deepCharcoal,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ironGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ironGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: neonGreen),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
