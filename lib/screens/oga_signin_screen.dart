import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main OGA Sign-In Screen (for returning users)
/// Sends magic link and redirects to confirm screen
class OGASignInScreen extends StatefulWidget {
  final String? errorMessage;
  const OGASignInScreen({super.key, this.errorMessage});

  @override
  State<OGASignInScreen> createState() => _OGASignInScreenState();
}

class _OGASignInScreenState extends State<OGASignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.errorMessage;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
      // Construct redirect URL for web
      final String webRedirect =
          Uri.base.origin; // ← CHANGED! Remove /#/confirm

      // Send magic link
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: webRedirect,
        shouldCreateUser: true,
      );

      // Show success dialog
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
          'We sent a verification link to $email\n\nClick the link to sign in to your account.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isLoading = false);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF00C806))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // OGA Logo
                Center(
                  child: Image.network(
                    'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/oga_logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'OGA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 60),

                // Title
                const Center(
                  child: Text(
                    'SIGN IN TO YOUR ACCOUNT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Center(
                  child: Text(
                    'Enter your email to receive a secure login link',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

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
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF00C806),
                    ),
                  ),
                  onSubmitted: (_) => _handleSignIn(),
                ),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Sign in button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C806),
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
                            'SEND MAGIC LINK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),

                // Back to home
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '← Back to Home',
                      style: TextStyle(color: Color(0xFF00C806), fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Security note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Magic links are secure, passwordless authentication',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
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
      ),
    );
  }
}
