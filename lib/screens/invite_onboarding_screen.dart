import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile setup screen shown after invite signup flow.
/// Collects first name, last name, and username before entering dashboard.
///
/// Flow: InviteWelcomeScreen → InviteOnboardingScreen → Dashboard
///
/// INTEGRATION IN main.dart:
/// 1. Import this file
/// 2. In the invite detection block (after setInvitedBy), route here instead of dashboard
/// 3. Or change InviteWelcomeScreen's "ENTER MY LIBRARY" to navigate here
class InviteOnboardingScreen extends StatefulWidget {
  const InviteOnboardingScreen({super.key});

  @override
  State<InviteOnboardingScreen> createState() => _InviteOnboardingScreenState();
}

class _InviteOnboardingScreenState extends State<InviteOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _usernameError;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _usernameError = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim().toLowerCase();
      final fullName = '$firstName $lastName';

      // Check if username is already taken
      if (username.isNotEmpty) {
        final existing = await Supabase.instance.client
            .from('profiles')
            .select('email')
            .eq('username', username)
            .neq('email', user.email!)
            .maybeSingle();

        if (existing != null) {
          setState(() {
            _usernameError = 'This username is already taken';
            _isSaving = false;
          });
          return;
        }
      }

      // Update profile
      await Supabase.instance.client
          .from('profiles')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'full_name': fullName,
            'username': username.isNotEmpty ? username : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('email', user.email!);

      debugPrint('✅ Profile updated: $fullName (@$username)');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Header icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF39FF14).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF39FF14),
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
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
                        'Tell us a bit about yourself',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // First Name
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'FIRST NAME',
                        hint: 'Enter your first name',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 20),

                      // Last Name
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'LAST NAME',
                        hint: 'Enter your last name',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 20),

                      // Username
                      _buildTextField(
                        controller: _usernameController,
                        label: 'USERNAME',
                        hint: 'Choose a username',
                        prefix: '@',
                        errorText: _usernameError,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (v.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9_]+$',
                            ).hasMatch(v.trim())) {
                              return 'Letters, numbers, and underscores only';
                            }
                          }
                          return null; // Username is optional
                        },
                      ),

                      const SizedBox(height: 8),

                      // Username hint
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Optional — you can set this later in Settings',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: const Color(
                              0xFF39FF14,
                            ).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'ENTER MY LIBRARY',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skip option
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/dashboard');
                              },
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
          style: const TextStyle(
            color: Colors.white70,
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
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.redAccent),
            filled: true,
            fillColor: const Color(0xFF121212),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
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
