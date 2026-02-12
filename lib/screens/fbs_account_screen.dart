import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FBS Login/Account Creation Screen
/// Shows character preview and email login
class FBSAccountScreen extends StatefulWidget {
  final String sessionId;
  final String characterName; // e.g., 'caustica'

  const FBSAccountScreen({
    super.key,
    required this.sessionId,
    required this.characterName,
  });

  @override
  State<FBSAccountScreen> createState() => _FBSAccountScreenState();
}

class _FBSAccountScreenState extends State<FBSAccountScreen> {
  final TextEditingController _emailController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Get character display name
  String get characterDisplayName {
    final name = widget.characterName.toUpperCase();
    // Add "BEE - " prefix for Caustica (based on your design)
    if (name == 'CAUSTICA') {
      return 'BEE - CAUSTICA';
    }
    return name;
  }

  /// Get character image URL
  String get characterImageUrl {
    return 'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/${widget.characterName.toLowerCase()}.png';
  }

  /// Handle sign in / create account
  /// Handle sign in / create account
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Construct the redirect URL for Web.
      // Flutter Web usually uses /#/ for internal routing.
      final String webRedirect = '${Uri.base.origin}/#/fbs-success';

      // 2. Send magic link
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: webRedirect,
        shouldCreateUser: true,
      );

      // 3. Show success message if everything worked
      if (mounted) {
        _showSuccessDialog(email);
      }
    } catch (e) {
      debugPrint('❌ Error sending magic link: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Delivery failed. Please check your email or try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Extracted Success Dialog for cleaner code
  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Check your email!',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'We sent a verification link to $email\n\nClick the link to complete your account setup. Check your spam folder if you don\'t see it.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isLoading = false);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF00FF00))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isDesktop ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left side - Character preview
        Expanded(child: _buildCharacterPreview()),
        // Right side - Login form
        Expanded(
          child: Container(
            color: const Color.fromARGB(255, 0, 0, 0),
            child: Center(child: _buildLoginForm()),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMobileLogo(),
          _buildCharacterPreview(),
          Container(
            color: const Color.fromARGB(255, 0, 0, 0),
            child: _buildLoginForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Image.network(
        'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/fbs_oga_logo_long.png',
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'FINALBOSS SOUR × OGA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterPreview() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character image
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              padding: const EdgeInsets.all(40),
              child: Image.network(
                characterImageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 200,
                    color: Colors.white54,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // "You are about to unlock:"
            const Text(
              'You are about to unlock:',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Character name
            Text(
              characterDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo (web only, mobile has it at top)
          if (MediaQuery.of(context).size.width > 900)
            Center(
              child: Image.network(
                'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/fbs_oga_logo_long.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'FINALBOSS SOUR × OGA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 60),

          // "Redemption requires an account"
          const Center(
            child: Text(
              'Redemption requires an account.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),

          // "SIGN IN WITH EMAIL"
          const Center(
            child: Text(
              'SIGN IN WITH EMAIL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Email input
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: 'your@email.com',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            ),
            onSubmitted: (_) => _handleSignIn(),
          ),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          const SizedBox(height: 24),

          // Sign in button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // "create a new account" link
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                children: [
                  const TextSpan(
                    text: "If you don't have an existing account, ",
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap:
                          _handleSignIn, // Same as sign in (magic link handles both)
                      child: const Text(
                        'create a new account',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' today!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
