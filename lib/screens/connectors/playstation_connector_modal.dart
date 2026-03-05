// ═══════════════════════════════════════════════════════════════════
// PLAYSTATION CONNECTOR MODAL — Sprint 16
// Two modes:
//   PlayStationConnectorMode.signIn  → "Sign in with PlayStation" (auth)
//   PlayStationConnectorMode.link    → "Link your PSN account" (from Settings)
//
// Flow:
//   1. Landing — shows PSN logo, description, permission checkbox
//   2. Connecting — animated loading state
//   3. Connected — shows linked PSN ID, game count, disconnect option
//
// Usage:
//   PlayStationConnectorModal.show(context, mode: PlayStationConnectorMode.link)
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PlayStationConnectorMode { signIn, link }

enum _ConnectorState { idle, connecting, connected }

class PlayStationConnectorModal extends StatefulWidget {
  final PlayStationConnectorMode mode;

  const PlayStationConnectorModal({super.key, required this.mode});

  static Future<bool?> show(
    BuildContext context, {
    PlayStationConnectorMode mode = PlayStationConnectorMode.link,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayStationConnectorModal(mode: mode),
    );
  }

  @override
  State<PlayStationConnectorModal> createState() =>
      _PlayStationConnectorModalState();
}

class _PlayStationConnectorModalState extends State<PlayStationConnectorModal>
    with SingleTickerProviderStateMixin {
  // ─── Palette ─────────────────────────────────────────
  static const Color _void = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF121212);
  static const Color _neonGreen = Color(0xFF39FF14);
  static const Color _iron = Color(0xFF2C2C2C);
  static const Color _white = Color(0xFFFFFFFF);
  // PlayStation blue
  static const Color _psnBlue = Color(0xFF003791);
  static const Color _psnLight = Color(0xFF0070D1);

  _ConnectorState _state = _ConnectorState.idle;
  bool _allowGameLibrary = true;
  bool _allowFriendsList = false;

  // Simulated connected account data (replace with real PSN OAuth response)
  Map<String, dynamic>? _connectedAccount;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkExistingConnection();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingConnection() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final row = await Supabase.instance.client
          .from('playstation_connections')
          .select(
            'psn_id, psn_display_name, games_count, allow_game_library, allow_friends_list, connected_at',
          )
          .eq('user_email', user.email!)
          .maybeSingle();
      if (mounted && row != null) {
        setState(() {
          _connectedAccount = row;
          _allowGameLibrary = row['allow_game_library'] as bool? ?? true;
          _allowFriendsList = row['allow_friends_list'] as bool? ?? false;
          _state = _ConnectorState.connected;
        });
      }
    } catch (e) {
      debugPrint('PSN check error: $e');
    }
  }

  Future<void> _connectPlayStation() async {
    setState(() => _state = _ConnectorState.connecting);
    _pulseController.repeat(reverse: true);

    // ── TODO: Replace with real PSN OAuth flow ──────────
    // 1. Open PSN OAuth URL in webview/browser
    // 2. Capture redirect with PSN code
    // 3. Exchange for access token server-side via n8n/edge function
    // 4. Store PSN ID + tokens in playstation_connections table
    // For now: simulate a 2s network call
    await Future.delayed(const Duration(seconds: 2));

    final simulatedAccount = {
      'psn_id': 'PSN-${_randomCode()}',
      'psn_display_name': 'Player_${_randomCode()}',
      'games_count': 47,
      'allow_game_library': _allowGameLibrary,
      'allow_friends_list': _allowFriendsList,
      'connected_at': DateTime.now().toIso8601String(),
    };

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('playstation_connections').upsert({
          'user_email': user.email!,
          ...simulatedAccount,
        });
      }
    } catch (e) {
      debugPrint('PSN save error: $e');
    }

    _pulseController.stop();
    if (mounted) {
      setState(() {
        _connectedAccount = simulatedAccount;
        _state = _ConnectorState.connected;
      });
    }
  }

  Future<void> _updatePermissions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('playstation_connections')
          .update({
            'allow_game_library': _allowGameLibrary,
            'allow_friends_list': _allowFriendsList,
          })
          .eq('user_email', user.email!);
    } catch (e) {
      debugPrint('PSN permission update error: $e');
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _iron),
        ),
        title: const Text(
          'DISCONNECT PLAYSTATION',
          style: TextStyle(
            color: _white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        content: const Text(
          'This will remove your PSN account link. OGAs deployed to PlayStation games may become unavailable.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: _white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'DISCONNECT',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('playstation_connections')
              .delete()
              .eq('user_email', user.email!);
        }
      } catch (e) {
        debugPrint('PSN disconnect error: $e');
      }
      if (mounted) {
        setState(() {
          _connectedAccount = null;
          _state = _ConnectorState.idle;
        });
      }
    }
  }

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(5, (i) => chars.codeUnitAt((rand >> i) % chars.length)),
    );
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _buildPSNLogo(size: 28),
                const SizedBox(width: 12),
                Text(
                  widget.mode == PlayStationConnectorMode.signIn
                      ? 'SIGN IN WITH PLAYSTATION'
                      : 'CONNECT PLAYSTATION',
                  style: const TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
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
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ConnectorState.connecting:
        return _buildConnectingState();
      case _ConnectorState.connected:
        return _buildConnectedState();
      case _ConnectorState.idle:
      default:
        return _buildIdleState();
    }
  }

  // ─── IDLE: Connect prompt ─────────────────────────────

  Widget _buildIdleState() {
    return Column(
      children: [
        // PSN Hero banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_psnBlue.withValues(alpha: 0.3), _charcoal],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _psnLight.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _buildPSNLogo(size: 52),
              const SizedBox(height: 16),
              Text(
                widget.mode == PlayStationConnectorMode.signIn
                    ? 'SIGN IN WITH YOUR\nPLAYSTATION ACCOUNT'
                    : 'LINK YOUR\nPLAYSTATION ACCOUNT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.mode == PlayStationConnectorMode.signIn
                    ? 'Use your existing PSN account to access OGA. No new password needed.'
                    : 'Connect your PSN account to deploy OGAs into PlayStation games and sync your gaming activity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Permissions section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _iron),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERMISSIONS',
                style: TextStyle(
                  color: _neonGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Always granted',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),

              // Always-on: PSN ID
              _buildPermissionRow(
                icon: Icons.account_circle_outlined,
                color: _neonGreen,
                title: 'PSN ID & Display Name',
                subtitle: 'Required to identify your account',
                value: true,
                locked: true,
                onChanged: null,
              ),
              const Divider(color: _iron, height: 24),

              // Optional permissions
              Text(
                'OPTIONAL',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              _buildPermissionRow(
                icon: Icons.sports_esports_outlined,
                color: _psnLight,
                title: 'Game Library',
                subtitle:
                    'See which games you play so we can recommend compatible OGAs and game partners',
                value: _allowGameLibrary,
                locked: false,
                onChanged: (val) {
                  setState(() => _allowGameLibrary = val ?? true);
                },
              ),
              const SizedBox(height: 16),
              _buildPermissionRow(
                icon: Icons.people_outline,
                color: _psnLight,
                title: 'Friends List',
                subtitle:
                    'Find PSN friends already on OGA to trade and lend characters',
                value: _allowFriendsList,
                locked: false,
                onChanged: (val) {
                  setState(() => _allowFriendsList = val ?? false);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Privacy note
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: _white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OGA never posts to your PSN account or accesses your payment information. You can revoke access at any time.',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.35),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Connect button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _connectPlayStation,
            icon: _buildPSNLogo(size: 20, color: Colors.black),
            label: Text(
              widget.mode == PlayStationConnectorMode.signIn
                  ? 'SIGN IN WITH PLAYSTATION'
                  : 'CONNECT PLAYSTATION',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _psnLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ─── CONNECTING: animated loading ────────────────────

  Widget _buildConnectingState() {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Opacity(
                opacity: _pulseAnimation.value,
                child: _buildPSNLogo(size: 56),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CONNECTING TO PLAYSTATION',
              style: TextStyle(
                color: _white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifying your PSN account...',
              style: TextStyle(
                color: _white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  backgroundColor: _iron,
                  valueColor: AlwaysStoppedAnimation(_psnLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CONNECTED: account info + permissions ────────────

  Widget _buildConnectedState() {
    final displayName =
        _connectedAccount?['psn_display_name'] as String? ?? 'PSN User';
    final psnId = _connectedAccount?['psn_id'] as String? ?? '';
    final gamesCount = _connectedAccount?['games_count'] as int? ?? 0;
    final connectedAt = _connectedAccount?['connected_at'] as String? ?? '';

    String connectedDate = '';
    if (connectedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(connectedAt);
        connectedDate = '${dt.month}/${dt.day}/${dt.year}';
      } catch (_) {}
    }

    return Column(
      children: [
        // Connected account card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_psnBlue.withValues(alpha: 0.2), _charcoal],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _psnLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _psnBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _psnLight.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(child: _buildPSNLogo(size: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (psnId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        psnId,
                        style: TextStyle(
                          color: _psnLight.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
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
                  'LINKED',
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
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _buildStatChip(Icons.sports_esports, '$gamesCount', 'GAMES'),
            const SizedBox(width: 12),
            if (connectedDate.isNotEmpty)
              _buildStatChip(
                Icons.calendar_today_outlined,
                connectedDate,
                'LINKED',
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Permissions (editable)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _iron),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'PERMISSIONS',
                    style: TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to update',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPermissionRow(
                icon: Icons.account_circle_outlined,
                color: _neonGreen,
                title: 'PSN ID & Display Name',
                subtitle: 'Always required',
                value: true,
                locked: true,
                onChanged: null,
              ),
              const Divider(color: _iron, height: 24),
              _buildPermissionRow(
                icon: Icons.sports_esports_outlined,
                color: _psnLight,
                title: 'Game Library',
                subtitle: 'Used for OGA recommendations',
                value: _allowGameLibrary,
                locked: false,
                onChanged: (val) {
                  setState(() => _allowGameLibrary = val ?? true);
                  _updatePermissions();
                },
              ),
              const SizedBox(height: 16),
              _buildPermissionRow(
                icon: Icons.people_outline,
                color: _psnLight,
                title: 'Friends List',
                subtitle: 'Find PSN friends on OGA',
                value: _allowFriendsList,
                locked: false,
                onChanged: (val) {
                  setState(() => _allowFriendsList = val ?? false);
                  _updatePermissions();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Done + Disconnect row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _disconnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(
                    color: Colors.red.shade400.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'DISCONNECT',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────

  Widget _buildPermissionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required bool locked,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: locked ? _white.withValues(alpha: 0.5) : _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.35),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (locked)
          Icon(
            Icons.lock_outline,
            size: 18,
            color: _white.withValues(alpha: 0.2),
          )
        else
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _neonGreen,
              activeTrackColor: _neonGreen.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: _iron,
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _iron),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _psnLight),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPSNLogo({double size = 32, Color? color}) {
    // PlayStation logo using text symbol — replace with actual asset if available
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'PS',
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AnimatedBuilder helper (re-export from Flutter) ─────
// (Already defined in character_detail_screen.dart — remove this if both
//  files are compiled together to avoid duplicate definition)
