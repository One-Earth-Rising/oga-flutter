import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmLoginScreen extends StatefulWidget {
  final String? tokenHash;
  final String? type;

  const ConfirmLoginScreen({super.key, this.tokenHash, this.type});

  @override
  State<ConfirmLoginScreen> createState() => _ConfirmLoginScreenState();
}

class _ConfirmLoginScreenState extends State<ConfirmLoginScreen> {
  final supabase = Supabase.instance.client;
  String? _confirmationUrl;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _extractConfirmationUrl();
  }

  void _extractConfirmationUrl() {
    try {
      final uri = Uri.base;
      debugPrint('📍 Full URI: $uri');
      debugPrint('📍 Fragment: ${uri.fragment}');

      String? tokenHash = widget.tokenHash;
      String? type = widget.type;

      debugPrint(
        '📍 Constructor params: tokenHash=${tokenHash != null ? "present (${tokenHash.length} chars)" : "null"}, type=$type',
      );

      // Fallback: parse from URL if not passed via constructor
      if (tokenHash == null) {
        if (uri.fragment.contains('?')) {
          final queryString = uri.fragment.split('?').last;
          final queryParams = Uri.splitQueryString(queryString);
          tokenHash = queryParams['token_hash'];
          type = queryParams['type'];
          if (tokenHash != null) {
            debugPrint('🔐 Got token_hash from fragment params');
          }
        }

        if (tokenHash == null) {
          tokenHash = uri.queryParameters['token_hash'];
          type = uri.queryParameters['type'];
          if (tokenHash != null) {
            debugPrint('🔐 Got token_hash from query params');
          }
        }

        // Legacy: full URL approach
        if (tokenHash == null) {
          if (uri.fragment.contains('?')) {
            final queryString = uri.fragment.split('?').last;
            final queryParams = Uri.splitQueryString(queryString);
            _confirmationUrl = queryParams['url'];
            if (_confirmationUrl != null) {
              _confirmationUrl = Uri.decodeComponent(_confirmationUrl!);
              debugPrint('🔐 Got legacy URL from fragment');
            }
          }
          if (_confirmationUrl == null) {
            _confirmationUrl = uri.queryParameters['url'];
            if (_confirmationUrl != null) {
              _confirmationUrl = Uri.decodeComponent(_confirmationUrl!);
              debugPrint('🔐 Got legacy URL from query params');
            }
          }
        }
      }

      // Reconstruct verify URL from token parts
      if (tokenHash != null && _confirmationUrl == null) {
        final supabaseUrl = 'https://jmbzrbteizvuqwukojzu.supabase.co';
        final redirectTo = Uri.encodeComponent('${uri.scheme}://${uri.host}/');

        _confirmationUrl =
            '$supabaseUrl/auth/v1/verify'
            '?token=$tokenHash'
            '&type=${type ?? 'signup'}'
            '&redirect_to=$redirectTo';

        debugPrint('🔐 Reconstructed verify URL from token_hash');
        debugPrint('📧 Confirmation URL: $_confirmationUrl');
      } else if (_confirmationUrl != null) {
        debugPrint('📧 Confirmation URL (legacy): $_confirmationUrl');
      } else {
        debugPrint('❌ No token_hash or URL found — confirmation will fail');
      }

      setState(() {});
    } catch (e) {
      debugPrint('❌ Error extracting URL: $e');
      setState(() {});
    }
  }

  Future<void> _handleConfirmation() async {
    if (_confirmationUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid confirmation link'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      debugPrint('🔐 Redirecting to: $_confirmationUrl');

      // Redirect browser to Supabase verification URL
      await launchUrl(
        Uri.parse(_confirmationUrl!),
        webOnlyWindowName: '_self', // Navigates in same tab (not new window)
      );
    } catch (e) {
      debugPrint('❌ Redirect error: $e');

      if (mounted) {
        setState(() => _isProcessing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redirect failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFixStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF39FF14).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF39FF14).withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo from Supabase Storage
                  Image.network(
                    'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-filles/oga_logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to text if logo fails to load
                      return const Text(
                        'OGA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Mail icon
                  const Icon(
                    Icons.mail_outline,
                    size: 60,
                    color: Color(0xFF00FF00),
                  ),
                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Confirm Your Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    _confirmationUrl != null
                        ? 'Click the button below to complete your login securely.'
                        : 'This link was opened in a different browser than where you signed up.',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Confirm button
                  if (_confirmationUrl != null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _handleConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CONFIRM & CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),

                  // Error state — PKCE browser mismatch instructions
                  if (_confirmationUrl == null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF39FF14),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'HOW TO FIX THIS',
                                style: TextStyle(
                                  color: Color(0xFF39FF14),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your sign-in link must be opened in the same browser where you started. Gmail and Mail apps use a built-in browser that breaks this.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFixStep('1', 'Go back to your email'),
                          const SizedBox(height: 8),
                          _buildFixStep('2', 'Tap ••• or the share icon'),
                          const SizedBox(height: 8),
                          _buildFixStep(
                            '3',
                            'Choose "Open in Safari" or "Open in Chrome"',
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF2C2C2C)),
                          const SizedBox(height: 14),
                          const Text(
                            'OR — copy the link from your email and paste it directly into Safari or Chrome:',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/signin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF2C2C2C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'REQUEST A NEW LINK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 60),

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
                            'This page protects your login from email scanners',
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
      ),
    );
  }
}
