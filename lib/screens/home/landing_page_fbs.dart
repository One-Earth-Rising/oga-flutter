import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oga_web_showcase/utils/image_helper.dart';

class LandingPageFBS extends StatefulWidget {
  const LandingPageFBS({super.key});

  @override
  State<LandingPageFBS> createState() => _LandingPageFBSState();
}

class _LandingPageFBSState extends State<LandingPageFBS> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final supabase = Supabase.instance.client;

  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_formatCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _formatCode() {
    final text = _codeController.text.toUpperCase().replaceAll('-', '');
    if (text.length > 12) return;

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 8) formatted += '-';
      formatted += text[i];
    }

    if (formatted != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  bool _isValidFormat(String code) {
    final regex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    return regex.hasMatch(code);
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    setState(() => _errorMessage = null);

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a redemption code');
      return;
    }

    if (!_isValidFormat(code)) {
      setState(() => _errorMessage = 'Invalid format. Use: ABCD-1234-EFGH');
      return;
    }

    setState(() => _isValidating = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      final sessionId = 'fbs_${DateTime.now().millisecondsSinceEpoch}';
      final characters = ['caustica', 'bigwell', 'brumblebutt'];
      final randomCharacter =
          characters[DateTime.now().second % characters.length];

      await supabase.from('profiles').insert({
        'session_id': sessionId,
        'full_name': 'FBS User',
        'starter_character': randomCharacter,
        'campaign_id': 'fbs_launch',
        'campaign_joined_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint(
        '✅ Profile created: $sessionId with character: $randomCharacter',
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/fbs-account',
          arguments: {'sessionId': sessionId, 'character': randomCharacter},
        );
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.black, // Guaranteed pure black background
      body: isDesktop ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  /// DESKTOP LAYOUT: Image Left (Black Ground), Code Right
  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left Side: Pure Hero Image on Black
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Image.network(
                CampaignImageHelper.heroPromo,
                fit: BoxFit.fitHeight,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white24,
                  size: 100,
                ),
              ),
            ),
          ),
        ),
        // Right Side: Code Entry
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(child: _buildCodeEntrySection()),
          ),
        ),
      ],
    );
  }

  /// MOBILE LAYOUT: Logo Top, Code Bottom (No Hero Image)
  Widget _buildMobileLayout() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            _buildBrandingLogo(), // Logo always stays on top for mobile
            const SizedBox(height: 60),
            _buildCodeEntrySection(showLogo: false),
          ],
        ),
      ),
    );
  }

  /// SHARED CODE ENTRY: Logo (Conditional), Input, and Submit
  Widget _buildCodeEntrySection({bool showLogo = true}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) _buildBrandingLogo(),
          if (showLogo) const SizedBox(height: 60),
          const Text(
            'ENTER CODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textInputAction:
                TextInputAction.go, // Changes 'Enter' key to 'Go' icon
            onSubmitted: (_) => _isValidating ? null : _submitCode(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1A1A), // Subtle dark gray for input
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              hintText: 'XXXX-XXXX-XXXX',
              hintStyle: const TextStyle(color: Colors.white24),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isValidating ? null : _submitCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00), // OGA Neon Green
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isValidating
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingLogo() {
    return Image.network(
      'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/fbs_oga_logo.png',
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Text(
        'FINALBOSS SOUR X OGA',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
