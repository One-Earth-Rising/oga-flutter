import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/friend_service.dart';
import '../services/analytics_service.dart';

/// Share Profile / Recruit Agents screen.
/// Shows QR code, invite code, share link, and referral reward.
class ShareProfileScreen extends StatefulWidget {
  final String? inviteCode;
  final String? displayName;

  const ShareProfileScreen({super.key, this.inviteCode, this.displayName});

  @override
  State<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends State<ShareProfileScreen> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color ironGrey = Color(0xFF2C2C2C);

  // Base URL uses hash routing for Flutter web
  static const String _baseUrl = 'https://oga.oneearthrising.com/#/invite';

  String? _inviteCode;
  bool _isLoading = true;
  bool _codeCopied = false;
  bool _linkCopied = false;

  String get _inviteLink => '$_baseUrl/$_inviteCode';

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackPageView('share_profile');
    _inviteCode = widget.inviteCode;
    if (_inviteCode != null) {
      _isLoading = false;
    } else {
      _loadInviteCode();
    }
  }

  Future<void> _loadInviteCode() async {
    final code = await FriendService.getMyInviteCode();
    setState(() {
      _inviteCode = code ?? 'OGA-XXXX';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: voidBlack,
      appBar: AppBar(
        backgroundColor: voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'SHARE PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 40,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Referral reward banner
                      _buildRewardBanner(),
                      const SizedBox(height: 28),

                      // QR Code card
                      _buildQrCard(),
                      const SizedBox(height: 28),

                      // Invite code row
                      _buildInviteCodeRow(),
                      const SizedBox(height: 20),

                      // Share invite link button (opens native share sheet)
                      _buildShareButton(),
                      const SizedBox(height: 16),

                      // Copy link button (clipboard only)
                      _buildCopyLinkButton(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // REFERRAL REWARD BANNER
  // ═══════════════════════════════════════════════════════════

  Widget _buildRewardBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: neonGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star, color: neonGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REFERRAL REWARD',
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invite 3 friends to unlock the \'Neon Breaker\' skin.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // QR CODE CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: QrImageView(
              data: _inviteLink,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              gapless: true,
              errorStateBuilder: (ctx, err) => const SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: Icon(Icons.qr_code, color: Colors.black38, size: 80),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'SCAN TO JOIN',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INVITE CODE ROW
  // ═══════════════════════════════════════════════════════════

  Widget _buildInviteCodeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR INVITE CODE',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _copyCode,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _codeCopied
                    ? neonGreen.withValues(alpha: 0.4)
                    : ironGrey,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _inviteCode!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _codeCopied
                      ? const Icon(
                          Icons.check,
                          color: neonGreen,
                          size: 22,
                          key: ValueKey('check'),
                        )
                      : Icon(
                          Icons.copy,
                          color: neonGreen.withValues(alpha: 0.6),
                          size: 22,
                          key: const ValueKey('copy'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARE BUTTON — Opens native share sheet
  // ═══════════════════════════════════════════════════════════

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: _shareInviteLink,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: neonGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, color: Colors.black, size: 18),
            SizedBox(width: 10),
            Text(
              'SHARE INVITE LINK',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COPY LINK BUTTON — Clipboard only
  // ═══════════════════════════════════════════════════════════

  Widget _buildCopyLinkButton() {
    return GestureDetector(
      onTap: _copyLink,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ironGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link,
              color: _linkCopied ? neonGreen : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _linkCopied ? 'LINK COPIED!' : 'COPY INVITE LINK',
              style: TextStyle(
                color: _linkCopied ? neonGreen : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode!));
    setState(() => _codeCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite code copied!'),
        backgroundColor: neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _inviteLink));
    setState(() => _linkCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied: $_inviteLink'),
        backgroundColor: neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInviteLink() {
    AnalyticsService.trackShareTapped();
    // Uses share_plus to open native share sheet
    // Uses share_plus to open native share sheet
    // On mobile: shows Mail, Messages, WhatsApp, etc.
    // On web: falls back to clipboard or browser share API
    final shareText =
        'Join me on OGA and get a free character!\n\n'
        'Use my invite code: $_inviteCode\n'
        '$_inviteLink';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Join OGA — One Character, Infinite Worlds',
      ),
    );
  }
}
