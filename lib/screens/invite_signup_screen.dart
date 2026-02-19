import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/friend_service.dart';

/// Helper to persist invite code across page reloads (uses shared_preferences
/// which maps to localStorage on web — but through Flutter's abstraction,
/// so no dart:html lint warnings).
class PendingInvite {
  static const _key = 'pending_invite_code';

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    debugPrint('💾 PendingInvite saved: $code');
  }

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    debugPrint('🗑️ PendingInvite cleared');
  }
}

/// Dedicated sign-up screen for invited users.
/// Streamlined: shows inviter info, email input, sends magic link.
/// No chatbot, no friction — just enter email and go.
/// Route: /#/invite-signup/<INVITE_CODE>
class InviteSignUpScreen extends StatefulWidget {
  final String inviteCode;
  final InviterProfile inviter;

  const InviteSignUpScreen({
    super.key,
    required this.inviteCode,
    required this.inviter,
  });

  @override
  State<InviteSignUpScreen> createState() => _InviteSignUpScreenState();
}

class _InviteSignUpScreenState extends State<InviteSignUpScreen> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color ironGrey = Color(0xFF2C2C2C);

  final _emailController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;
  String _sentToEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: voidBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 40,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _emailSent ? _buildEmailSentState() : _buildSignUpForm(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SIGN-UP FORM
  // ═══════════════════════════════════════════════════════════

  Widget _buildSignUpForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Image.asset(
          'assets/logo.png',
          height: 36,
          errorBuilder: (context, error, stackTrace) => const Text(
            'OGA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Inviter card
        _buildInviterCard(),
        const SizedBox(height: 28),

        // Reward badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: neonGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: neonGreen.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: neonGreen.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sign up now and receive a free character skin',
                  style: TextStyle(
                    color: neonGreen.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Email input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR EMAIL',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: deepCharcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _error != null
                      ? Colors.red.withValues(alpha: 0.5)
                      : _focusNode.hasFocus
                      ? neonGreen.withValues(alpha: 0.4)
                      : ironGrey,
                ),
              ),
              child: TextField(
                controller: _emailController,
                focusNode: _focusNode,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.white.withValues(alpha: 0.25),
                    size: 20,
                  ),
                ),
                onSubmitted: (_) => _sendMagicLink(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Create account button
        GestureDetector(
          onTap: _isLoading ? null : _sendMagicLink,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isLoading ? neonGreen.withValues(alpha: 0.5) : neonGreen,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: neonGreen.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
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
                      'CREATE MY ACCOUNT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Terms text
        Text(
          'We\'ll send you a magic link to sign in.\nNo password needed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Back to invite link
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            '← Back to ${widget.inviter.displayName}\'s library',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INVITER CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildInviterCard() {
    final inviter = widget.inviter;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ironGrey),
      ),
      child: Column(
        children: [
          // "Invited by" label
          Text(
            'YOU\'VE BEEN INVITED BY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: inviter.characterColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: inviter.characterColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: inviter.avatarUrl != null
                  ? Image.network(
                      inviter.avatarUrl!,
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(),
                    )
                  : _buildFallbackAvatar(),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            inviter.displayName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          if (inviter.username.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@${inviter.username}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Invite code chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: neonGreen.withValues(alpha: 0.6),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'CODE: ${widget.inviteCode}',
                  style: TextStyle(
                    color: neonGreen.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      height: 64,
      width: 64,
      color: deepCharcoal,
      child: const Icon(Icons.person, color: Colors.white38, size: 28),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMAIL SENT STATE
  // ═══════════════════════════════════════════════════════════

  Widget _buildEmailSentState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Image.asset(
          'assets/logo.png',
          height: 36,
          errorBuilder: (context, error, stackTrace) => const Text(
            'OGA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Success icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: neonGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: neonGreen.withValues(alpha: 0.8),
            size: 32,
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'CHECK YOUR EMAIL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a magic link to',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _sentToEmail,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Click the link in the email to complete sign-up.\nIt expires in 60 seconds.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Resend button
        GestureDetector(
          onTap: _isLoading ? null : _sendMagicLink,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ironGrey),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white38,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'RESEND LINK',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Try different email
        GestureDetector(
          onTap: () => setState(() {
            _emailSent = false;
            _emailController.clear();
          }),
          child: Text(
            'Use a different email',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH LOGIC
  // ═══════════════════════════════════════════════════════════

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim().toLowerCase();

    // Basic validation
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Persist invite code — survives page reload on web
      await PendingInvite.save(widget.inviteCode);

      // Send magic link via Supabase
      // Invite code also passed via user metadata (works for new users)
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: _buildRedirectUrl(),
        data: {'invite_code': widget.inviteCode},
      );

      debugPrint('✅ Magic link sent to $email (invite: ${widget.inviteCode})');

      setState(() {
        _emailSent = true;
        _sentToEmail = email;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error sending magic link: $e');
      setState(() {
        _error = 'Failed to send email. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Build the redirect URL that includes the invite code.
  /// After auth, the confirm screen / callback can extract this
  /// and call setInvitedBy() to trigger auto-friend linking.
  String _buildRedirectUrl() {
    final base = Uri.base;
    final port = (base.port != 80 && base.port != 443) ? ':${base.port}' : '';
    final redirectUrl =
        '${base.scheme}://${base.host}$port/#/confirm?invite=${widget.inviteCode}';
    debugPrint('🔗 Redirect URL: $redirectUrl');
    return redirectUrl;
  }
}
