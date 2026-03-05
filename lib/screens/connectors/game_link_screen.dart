// ═══════════════════════════════════════════════════════════════════
// GAME LINK SCREEN — Sprint 16
// Route: /link  or  /link?code=XXXXX
//
// This is the page at oga.games/link — the companion web page for
// the in-game QR flow on PlayStation (and other consoles).
//
// Flow:
//   1. Game shows QR + short code on-screen (e.g. "3SYVK")
//   2. Player scans QR → lands here (or types oga.games/link manually)
//   3. If not logged in → redirect to sign-in, return here after
//   4. Player enters code → OGA verifies it matches an active game session
//   5. Success → shows which game is linked + OGAs deployed to it
//   6. Game receives confirmation → player sees their OGA in-game
//
// Code lifecycle (Supabase):
//   game_link_sessions table:
//     id uuid, code text UNIQUE, game_id text, game_name text,
//     game_icon_url text, platform text, status text (pending/linked/expired),
//     linked_email text, expires_at timestamptz, created_at timestamptz
//
// Add route in main.dart:
//   '/link' or '/#/link' → GameLinkScreen()
//   Also handles /#/link?code=XXXXX (pre-fills code)
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class GameLinkScreen extends StatefulWidget {
  final String? prefillCode;

  const GameLinkScreen({super.key, this.prefillCode});

  static Future<void> show(BuildContext context, {String? prefillCode}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameLinkScreen(prefillCode: prefillCode),
    );
  }

  @override
  State<GameLinkScreen> createState() => _GameLinkScreenState();
}

class _GameLinkScreenState extends State<GameLinkScreen>
    with SingleTickerProviderStateMixin {
  // ─── Palette ─────────────────────────────────────────
  static const Color _void = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF121212);
  static const Color _neonGreen = Color(0xFF39FF14);
  static const Color _iron = Color(0xFF2C2C2C);
  static const Color _white = Color(0xFFFFFFFF);

  // ─── State ───────────────────────────────────────────
  late TextEditingController _codeController;
  late FocusNode _codeFocus;
  bool _isSubmitting = false;
  String? _error;
  _LinkState _linkState = _LinkState.entry;
  int _activeTab = 0; // 0 = enter code, 1 = scan QR
  bool _qrScanning = false;
  Map<String, dynamic>? _linkedSession;
  List<Map<String, dynamic>> _deployedOgas = [];

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.prefillCode ?? '');
    _codeFocus = FocusNode();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Auto-submit if code was pre-filled from URL
    if (widget.prefillCode != null && widget.prefillCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitCode());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the code shown in your game.');
      return;
    }
    if (code.length < 4) {
      setState(() => _error = 'Code must be at least 4 characters.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'You must be signed in to link a game.';
          _isSubmitting = false;
        });
        return;
      }

      // Look up the game session by code
      final session = await Supabase.instance.client
          .from('game_link_sessions')
          .select('*')
          .eq('code', code)
          .eq('status', 'pending')
          .maybeSingle();

      if (session == null) {
        // Check if expired
        final expired = await Supabase.instance.client
            .from('game_link_sessions')
            .select('status, expires_at')
            .eq('code', code)
            .maybeSingle();

        if (expired != null && expired['status'] == 'expired') {
          setState(() {
            _error =
                'This code has expired. Return to the game and request a new one.';
            _isSubmitting = false;
          });
        } else if (expired != null && expired['status'] == 'linked') {
          setState(() {
            _error = 'This code has already been used.';
            _isSubmitting = false;
          });
        } else {
          setState(() {
            _error =
                'Code not found. Check the code shown in your game and try again.';
            _isSubmitting = false;
          });
        }
        return;
      }

      // Check expiry
      if (session['expires_at'] != null) {
        final expiresAt = DateTime.parse(session['expires_at'] as String);
        if (DateTime.now().toUtc().isAfter(expiresAt)) {
          await Supabase.instance.client
              .from('game_link_sessions')
              .update({'status': 'expired'})
              .eq('code', code);
          setState(() {
            _error =
                'This code has expired. Return to the game to get a new one.';
            _isSubmitting = false;
          });
          return;
        }
      }

      // Link the session to this user
      await Supabase.instance.client
          .from('game_link_sessions')
          .update({
            'status': 'linked',
            'linked_email': user.email!,
            'linked_at': DateTime.now().toIso8601String(),
          })
          .eq('code', code);

      // Load user's owned OGAs to show as "deployed"
      final ownedRows = await Supabase.instance.client
          .from('character_ownership')
          .select('character_id')
          .eq('owner_email', user.email!)
          .eq('status', 'active')
          .limit(6);

      final ownedCharIds = (ownedRows as List)
          .map((r) => r['character_id'] as String)
          .toList();

      // Fetch character metadata
      List<Map<String, dynamic>> ogaData = [];
      if (ownedCharIds.isNotEmpty) {
        final chars = await Supabase.instance.client
            .from('characters')
            .select('id, name, hero_image_url')
            .inFilter('id', ownedCharIds);
        ogaData = List<Map<String, dynamic>>.from(chars);
      }

      if (mounted) {
        setState(() {
          _linkedSession = session;
          _deployedOgas = ogaData;
          _linkState = _LinkState.success;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      debugPrint('Game link error: $e');
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      decoration: const BoxDecoration(
        color: _void,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: _iron),
          left: BorderSide(color: _iron),
          right: BorderSide(color: _iron),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _iron,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Top bar: logo + label + X
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
            child: Row(
              children: [
                Image.network(
                  'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-filles/oga_logo.png',
                  height: 28,
                  errorBuilder: (_, __, _e) => const Text(
                    'OGA',
                    style: TextStyle(
                      color: _neonGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'LINK ACCOUNT',
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: _iron, height: 1),
          // Tab bar (hidden on success)
          if (_linkState != _LinkState.success)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _buildTab(0, Icons.keyboard, 'ENTER CODE'),
                  const SizedBox(width: 8),
                  _buildTab(1, Icons.qr_code_scanner, 'SCAN QR'),
                ],
              ),
            ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _linkState == _LinkState.success
                  ? _buildSuccessState()
                  : (_activeTab == 0
                        ? _buildEntryState()
                        : _buildQrScanState()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = index;
          if (index == 1) _startQrScanner();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _neonGreen.withValues(alpha: 0.1) : _charcoal,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? _neonGreen.withValues(alpha: 0.5) : _iron,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? _neonGreen : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _neonGreen : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // OGA logo wordmark
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) => Container(
            decoration: _linkState == _LinkState.success
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _neonGreen.withValues(
                          alpha: _glowAnimation.value * 0.4,
                        ),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  )
                : null,
            child: child,
          ),
          child: Text(
            'OGA',
            style: TextStyle(
              color: _neonGreen,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              fontFamily: 'Helvetica',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _linkState == _LinkState.success ? 'GAME LINKED' : 'LINK ACCOUNT',
          style: TextStyle(
            color: _white.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // ─── Entry state ──────────────────────────────────────

  Widget _buildEntryState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _iron),
      ),
      child: Column(
        children: [
          // Instruction
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _neonGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _neonGreen.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.videogame_asset_outlined,
                  color: _neonGreen.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter the code shown in your game to connect your OGA account.',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Code label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ENTER CODE',
              style: TextStyle(
                color: _white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Code input
          TextField(
            controller: _codeController,
            focusNode: _codeFocus,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            maxLength: 8,
            decoration: InputDecoration(
              counterText: '',
              hintText: '· · · · ·',
              hintStyle: TextStyle(
                color: _white.withValues(alpha: 0.15),
                fontSize: 24,
                letterSpacing: 10,
              ),
              filled: true,
              fillColor: _void,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _iron),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _iron),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _neonGreen, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
            ),
            onSubmitted: (_) => _submitCode(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 8),

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _neonGreen.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      '[ SUBMIT ]',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Divider + sign in link
          Row(
            children: [
              Expanded(child: Divider(color: _iron)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'not signed in?',
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.25),
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(child: Divider(color: _iron)),
            ],
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signin'),
            child: Text(
              'SIGN IN TO YOUR OGA ACCOUNT',
              style: TextStyle(
                color: _neonGreen.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success state ─────────────────────────────────────

  Widget _buildSuccessState() {
    final gameName = _linkedSession?['game_name'] as String? ?? 'Your Game';
    final platform = _linkedSession?['platform'] as String? ?? 'PlayStation';
    final gameIcon = _linkedSession?['game_icon_url'] as String?;

    return Column(
      children: [
        // Success banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_neonGreen.withValues(alpha: 0.12), _charcoal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _neonGreen.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Checkmark
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _neonGreen, width: 2),
                ),
                child: const Icon(Icons.check, color: _neonGreen, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'ACCOUNT LINKED!',
                style: TextStyle(
                  color: _neonGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your OGA account is now connected to $gameName on $platform.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Game info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _iron),
          ),
          child: Row(
            children: [
              // Game icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _iron,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: gameIcon != null && gameIcon.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          gameIcon,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildGameIconFallback(gameName),
                        ),
                      )
                    : _buildGameIconFallback(gameName),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameName.toUpperCase(),
                      style: const TextStyle(
                        color: _white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.videogame_asset,
                          size: 12,
                          color: _white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          platform,
                          style: TextStyle(
                            color: _white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Deployed OGAs
        if (_deployedOgas.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _charcoal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _iron),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'YOUR OGAs IN THIS GAME',
                      style: TextStyle(
                        color: _white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _neonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_deployedOgas.length} DEPLOYED',
                        style: const TextStyle(
                          color: _neonGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _deployedOgas.length,
                    itemBuilder: (context, index) {
                      final oga = _deployedOgas[index];
                      final name = oga['name'] as String? ?? '?';
                      final imageUrl = oga['hero_image_url'] as String?;
                      return Container(
                        width: 64,
                        margin: EdgeInsets.only(
                          right: index < _deployedOgas.length - 1 ? 10 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: _void,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _neonGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(9),
                                ),
                                child: imageUrl != null
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: _neonGreen,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: _neonGreen,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                name.toUpperCase(),
                                style: TextStyle(
                                  color: _white.withValues(alpha: 0.6),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Return to game instruction
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _neonGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _neonGreen.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sports_esports,
                color: _neonGreen.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Return to your game — your OGAs should now be available. This page can be closed.',
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Link another game
        TextButton(
          onPressed: () {
            setState(() {
              _linkState = _LinkState.entry;
              _codeController.clear();
              _linkedSession = null;
              _deployedOgas = [];
            });
          },
          child: Text(
            'LINK ANOTHER GAME',
            style: TextStyle(
              color: _white.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  void _startQrScanner() {
    setState(() => _qrScanning = true);
  }

  void _onQrDetected(String code) {
    if (!_qrScanning) return;
    setState(() {
      _qrScanning = false;
      _activeTab = 0;
      _codeController.text = code;
    });
    // Small delay so user sees the code filled in, then auto-submit
    Future.delayed(const Duration(milliseconds: 400), _submitCode);
  }

  Widget _buildQrScanState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _iron),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QR Scanner (mobile_scanner package)
                MobileScanner(
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null && code.isNotEmpty) {
                      // QR encodes the raw code or the full URL
                      // e.g. "3SYVK" or "https://oga.games/link?code=3SYVK"
                      final extracted =
                          Uri.tryParse(code)?.queryParameters['code'] ?? code;
                      _onQrDetected(extracted.toUpperCase());
                    }
                  },
                ),
                // Scan frame overlay
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _neonGreen.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Point your camera at the QR code shown in your game.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _white.withValues(alpha: 0.45),
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _activeTab = 0),
          child: Text(
            'ENTER CODE MANUALLY INSTEAD',
            style: TextStyle(
              color: _white.withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameIconFallback(String gameName) {
    return Container(
      decoration: BoxDecoration(
        color: _iron,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          gameName.isNotEmpty ? gameName[0].toUpperCase() : 'G',
          style: const TextStyle(
            color: _white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

enum _LinkState { entry, success }

// ─── AnimatedBuilder helper ───────────────────────────────────────
// (Remove if already defined in character_detail_screen.dart)
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
