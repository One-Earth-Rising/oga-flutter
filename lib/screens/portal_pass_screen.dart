// lib/screens/portal_pass_screen.dart
// Sprint 17 — Portal Pass Screen (FBS Character Unlock)
// Shows cross-game progression and FBS candy unlock flow.
// Replaces/extends the existing portal pass section from the character detail screen.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/fbs_service.dart';
import '../modals/fbs_redeem_modal.dart';
import 'fbs_qr_scanner_screen.dart' show FbsQrScannerSheet;

class PortalPassScreen extends StatefulWidget {
  const PortalPassScreen({super.key});

  @override
  State<PortalPassScreen> createState() => _PortalPassScreenState();
}

class _PortalPassScreenState extends State<PortalPassScreen> {
  // ─── Colors ─────────────────────────────────────────────────
  static const _black = Color(0xFF000000);
  static const _charcoal = Color(0xFF121212);
  static const _ironGrey = Color(0xFF2C2C2C);
  static const _neonGreen = Color(0xFF39FF14);
  static const _white = Color(0xFFFFFFFF);
  static const _deepSurface = Color(0xFF0A0A0A);

  // FBS brand — electric blue/cyan used in the Guggimon-style cyberpunk aesthetic
  static const _fbsAccent = Color(0xFF00CFCF);

  // ─── State ───────────────────────────────────────────────────
  List<FbsCharacter> _fbsCharacters = [];
  bool _loading = true;
  String? _successCharacterId;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = ModalRoute.of(context)?.settings.arguments as String?;
      if (code != null && mounted) {
        FbsRedeemModal.show(
          context,
          onSuccess: _onCodeRedeemed,
          initialCode: code,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final chars = await FbsService.loadFbsCharactersForUser();
    if (mounted) {
      setState(() {
        _fbsCharacters = chars;
        _loading = false;
      });
    }
  }

  void _onCodeRedeemed(String characterId) {
    setState(() {
      _successCharacterId = characterId;
      for (final c in _fbsCharacters) {
        if (c.id == characterId) c.isOwned = true;
      }
    });

    // Show snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _neonGreen),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: _neonGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              '${characterId.toUpperCase()} added to your library!',
              style: const TextStyle(
                color: _white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _black,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────
          SliverAppBar(
            backgroundColor: _black,
            expandedHeight: isDesktop ? 200 : 160,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Image.network(
                  'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-files/fbs_season_1_cobrand_logo.png',
                  height: 32,
                  errorBuilder: (_, __, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(color: _black),
                    child: Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _neonGreen.withValues(alpha: 0.15),
                              blurRadius: 120,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _neonGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BETA',
                                  style: TextStyle(
                                    color: _black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    fontFamily: 'Helvetica Neue',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'PORTAL PASS',
                                style: TextStyle(
                                  color: _white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  fontFamily: 'Helvetica Neue',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'YOUR MULTIVERSE\nLIBRARY',
                            style: TextStyle(
                              color: _white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: 1,
                              fontFamily: 'Helvetica Neue',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildFbsUnlockTab(isDesktop)),
        ],
      ),
    );
  }

  Widget _gameProgressCard(String gameName) {
    final progressMap = {
      'FORTNITE': 0.72,
      'STREET FIGHTER 6': 0.45,
      'DRAGON BALL XENOVERSE 2': 0.28,
    };
    final progress = progressMap[gameName] ?? 0.0;
    final pct = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gameName,
                style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: _neonGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: _ironGrey,
              valueColor: const AlwaysStoppedAnimation(_neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final stats = [
      ('GAMES PLAYED', '3'),
      ('CHARACTERS OWNED', '1'),
      ('TOTAL XP', '4,820'),
      ('PORTAL USES', '12'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: stats.map(((String label, String val) stat) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _charcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _ironGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat.$2,
                style: const TextStyle(
                  color: _neonGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.$1,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 1,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _comingSoonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ironGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: _neonGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE PORTAL — COMING SOON',
                  style: TextStyle(
                    color: _white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Automated character transfers between games. One character, infinite worlds.',
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: FBS Unlock ───────────────────────────────────────
  Widget _buildFbsUnlockTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero / Challenge Card ──────────────────────────
          _fbsChallengeCard(),
          const SizedBox(height: 28),

          // ── Unlock CTAs ────────────────────────────────────
          _sectionLabel('UNLOCK OPTIONS'),
          const SizedBox(height: 14),
          MediaQuery.of(context).size.width > 600
              ? _enterCodeButton()
              : Row(
                  children: [
                    Expanded(child: _scanQrButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _enterCodeButton()),
                  ],
                ),
          const SizedBox(height: 32),

          // ── FBS Character Grid ─────────────────────────────
          _sectionLabel('FBS CHARACTERS'),
          const SizedBox(height: 6),
          Text(
            'Each code unlocks one unique character. Collect them all.',
            style: TextStyle(
              color: _white.withValues(alpha: 0.4),
              fontSize: 13,
              fontFamily: 'Helvetica Neue',
            ),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: _neonGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            isDesktop ? _fbsCharacterGridDesktop() : _fbsCharacterGridMobile(),

          const SizedBox(height: 32),
          _whereToFindCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _fbsChallengeCard() {
    final owned = _fbsCharacters.where((c) => c.isOwned).length;
    final total = _fbsCharacters.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fbsAccent.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: _fbsAccent.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FBS logo row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _fbsAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FBS',
                  style: TextStyle(
                    color: _black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'FINAL BOSS SOUR',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.5),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _ironGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$owned / $total',
                  style: const TextStyle(
                    color: _neonGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'BUY CANDY.\nUNLOCK LEGENDS.',
            style: TextStyle(
              color: _white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: 0.5,
              fontFamily: 'Helvetica Neue',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Purchase Final Boss Sour candy at Walmart. Each bag contains a unique code that unlocks an exclusive OGA character — yours to keep, trade, and play across games.',
            style: TextStyle(
              color: _white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.5,
              fontFamily: 'Helvetica Neue',
            ),
          ),
          const SizedBox(height: 16),

          // Collection progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? owned / total : 0,
              minHeight: 5,
              backgroundColor: _ironGrey,
              valueColor: AlwaysStoppedAnimation(
                owned == total && total > 0 ? _neonGreen : _fbsAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            owned == total && total > 0
                ? 'COLLECTION COMPLETE'
                : '$owned OF $total CHARACTERS UNLOCKED',
            style: TextStyle(
              color: owned == total && total > 0
                  ? _neonGreen
                  : _white.withValues(alpha: 0.35),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontFamily: 'Helvetica Neue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanQrButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final code = await FbsQrScannerSheet.show(context);
        if (code != null && mounted) {
          FbsRedeemModal.show(
            context,
            onSuccess: _onCodeRedeemed,
            initialCode: code,
          );
        }
      },

      icon: const Icon(Icons.qr_code_scanner, size: 18),
      label: const Text('SCAN QR CODE'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _white,
        side: const BorderSide(color: _ironGrey),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          fontFamily: 'Helvetica Neue',
        ),
      ),
    );
  }

  Widget _enterCodeButton() {
    return ElevatedButton.icon(
      onPressed: () {
        FbsRedeemModal.show(context, onSuccess: _onCodeRedeemed);
      },
      icon: const Icon(Icons.confirmation_number_outlined, size: 18),
      label: const Text('ENTER CODE'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _neonGreen,
        foregroundColor: _black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          fontFamily: 'Helvetica Neue',
        ),
      ),
    );
  }

  // ─── FBS Character Grids ─────────────────────────────────────
  Widget _fbsCharacterGridMobile() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: _fbsCharacters.map(_fbsCharacterCard).toList(),
    );
  }

  Widget _fbsCharacterGridDesktop() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.72,
      children: _fbsCharacters.map(_fbsCharacterCard).toList(),
    );
  }

  Widget _fbsCharacterCard(FbsCharacter char) {
    final isUnlocked = char.isOwned;
    final isNewlyUnlocked = _successCharacterId == char.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNewlyUnlocked
              ? _neonGreen
              : isUnlocked
              ? _neonGreen.withValues(alpha: 0.4)
              : _ironGrey,
          width: isNewlyUnlocked ? 1.5 : 1,
        ),
        boxShadow: isNewlyUnlocked
            ? [
                BoxShadow(
                  color: _neonGreen.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Character image / silhouette
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: Image.network(
                'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/characters/heroes/${char.id}.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) =>
                    _fbsPlaceholder(char, locked: !isUnlocked),
              ),
            ),
          ),

          // Locked overlay
          if (!isUnlocked)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: Container(
                  color: _black.withValues(alpha: 0.6),
                  child: Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: _neonGreen.withValues(alpha: 0.6),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Info section
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _charcoal,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    char.name,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontFamily: 'Helvetica Neue',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    char.flavor,
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontFamily: 'Helvetica Neue',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? _neonGreen.withValues(alpha: 0.12)
                          : _ironGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUnlocked ? 'OWNED' : 'LOCKED',
                      style: TextStyle(
                        color: isUnlocked
                            ? _neonGreen
                            : _white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tap to unlock (locked cards)
          if (!isUnlocked)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      FbsRedeemModal.show(context, onSuccess: _onCodeRedeemed),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fbsPlaceholder(FbsCharacter char, {required bool locked}) {
    return Container(
      color: locked ? const Color(0xFF0A0A0A) : _charcoal,
      child: Center(
        child: Text(
          char.name.substring(0, 1),
          style: TextStyle(
            color: locked
                ? const Color(0xFF222222)
                : _neonGreen.withValues(alpha: 0.3),
            fontSize: 52,
            fontWeight: FontWeight.w900,
            fontFamily: 'Helvetica Neue',
          ),
        ),
      ),
    );
  }

  Widget _whereToFindCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ironGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.storefront_outlined, color: _white, size: 18),
              const SizedBox(width: 10),
              const Text(
                'FIND US IN STORE & PLAY TODAY',
                style: TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Walmart callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _deepSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0071CE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'WALMART',
                        style: TextStyle(
                          color: _white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontFamily: 'Helvetica Neue',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'FROM CANDY AISLE TO CONSOLE',
                      style: TextStyle(
                        color: _white.withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 1,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '\$2.98',
                      style: const TextStyle(
                        color: _neonGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'NOW AVAILABLE AT OVER 1,900 LOCATIONS',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: 'Helvetica Neue',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Each bag contains a unique code. Unlock up to four minibosses — one per flavor purchased.',
            style: TextStyle(
              color: _white.withValues(alpha: 0.45),
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Helvetica Neue',
            ),
          ),
          const SizedBox(height: 18),

          // CTA buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://finalbosssour.com/pages/store-locator'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.store_outlined, size: 15),
                  label: const Text('STORE LOCATOR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _white,
                    side: const BorderSide(color: _ironGrey),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://finalbosssour.com/collections/shop-all-flavors',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                  label: const Text('SHOP ONLINE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: _black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: _white.withValues(alpha: 0.35),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}
