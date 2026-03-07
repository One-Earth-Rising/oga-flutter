// ═══════════════════════════════════════════════════════════════════
// CHARACTER DETAIL SCREEN — Sprint 14
// ═══════════════════════════════════════════════════════════════════
// Full Figma-matching detail view with:
//   • Dramatic hero section with title overlay
//   • Character description & lore
//   • Game Variations (Multigameverse) horizontal carousel
//   • Portal Pass progress + tasks
//   • Special Rewards carousel
//   • Ownership History chain (owners-only, expandable)
//   • Gameplay Media gallery
//   • CHARACTER LOCKED state for unowned assets
//   • BORROWED / LENT OUT / TRADE PENDING states
//
// Layout:
//   Desktop (>900px): Split pane — hero left, info right
//   Mobile (<900px): Full-bleed hero scrolling into content
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../models/oga_character.dart';
import '../widgets/oga_image.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/invite_service.dart';
import '../services/analytics_service.dart';
import '../modals/trade_proposal_modal.dart';
import '../modals/friends_who_own_modal.dart';
import '../modals/get_character_modal.dart';
import '../widgets/notification_bell_widget.dart';
import '../modals/lend_proposal_modal.dart';
import '../config/oga_storage.dart';
import '../services/lend_service.dart';
import '../services/friend_service.dart';
import '../widgets/portal_pass_section.dart';

// ─── Brand Colors (Heimdal V2) ──────────────────────────────
const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);

class CharacterDetailScreen extends StatefulWidget {
  final OGACharacter character;
  final bool isOwned;
  final bool isGuest;
  final bool isBorrowed;
  final bool isLentOut;
  final bool isPendingTrade;
  final Map<String, dynamic>? lendInfo;
  final Map<String, dynamic>? pendingTradeInfo;
  final String? inviterName;
  final String? ownerEmail;
  final String? ownerName;
  final String? assetId;
  const CharacterDetailScreen({
    super.key,
    required this.character,
    this.isOwned = false,
    this.isGuest = false,
    this.isBorrowed = false,
    this.isLentOut = false,
    this.isPendingTrade = false,
    this.lendInfo,
    this.pendingTradeInfo,
    this.inviterName,
    this.ownerEmail,
    this.ownerName,
    this.assetId,
  });

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen>
    with SingleTickerProviderStateMixin {
  // Currently selected game variation (for hero image swap)
  int _selectedVariationIndex = -1; // -1 = default hero
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late PageController _heroPageController;

  OGACharacter get ch => widget.character;
  bool get owned => widget.isOwned;
  bool get isGuest => widget.isGuest;
  bool get isBorrowed => widget.isBorrowed;
  bool get isLentOut => widget.isLentOut;
  bool get isPendingTrade => widget.isPendingTrade;

  /// True if user can interact with features (owns or borrows)
  bool get canInteract => owned || isBorrowed;

  // Gameplay videos loaded from character_gameplay_videos table
  List<Map<String, dynamic>> _gameplayVideos = [];

  // Cached invite code for share URL generation
  String? _userInviteCode;
  bool _isFetchingInviteCode = false;

  // ── Asset ID for this specific OGA instance ──
  String? _assetId;

  // ── Real ownership history (from DB) ──
  List<Map<String, dynamic>> _ownershipTimeline = [];
  bool _isLoadingHistory = true;
  bool _isHistoryExpanded = false;

  // ── Lend counterparty info (loaded from DB) ──
  Map<String, dynamic>? _lendCounterpartyProfile;
  Map<String, dynamic>? _tradeCounterpartyProfile;
  Map<String, dynamic>? _fullTradeDetails; // full trade row from DB
  bool _isTradeActionLoading =
      false; // ── Lend counterparty info (loaded from DB) ──
  static const Color _lendCyan = Color(0xFF00BCD4);
  static const Color _tradeAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Only animate glow for owned characters that aren't lent out or pending trade
    if (owned && !isLentOut && !isPendingTrade) {
      _glowController.repeat(reverse: true);
    }
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _heroPageController = PageController(initialPage: 0);
    AnalyticsService.trackCharacterViewed(
      ch.id,
      game: ch.gameVariations.isNotEmpty
          ? ch.gameVariations.first.gameName
          : null,
      owned: owned,
    );
    _assetId = widget.assetId;
    _loadOwnershipHistory();
    _loadCounterpartyProfiles();
    _loadGameplayVideos();
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnershipHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final events = <Map<String, dynamic>>[];
      final emails = <String>{};

      // ── Resolve asset_id if not passed from dashboard ──────
      // This happens when the user owns this character and
      // _assetId wasn't forwarded through route args.
      if (_assetId == null) {
        final userEmail = supabase.auth.currentUser?.email;
        if (userEmail != null) {
          final row = await supabase
              .from('character_ownership')
              .select('asset_id')
              .eq('character_id', ch.id)
              .eq('owner_email', userEmail)
              .eq('status', 'active')
              .maybeSingle();
          if (row != null) {
            _assetId = row['asset_id'] as String?;
            debugPrint('✅ Resolved asset_id from DB: $_assetId');
          }
        }
      }

      // If still null, nothing to show
      if (_assetId == null || _assetId!.isEmpty) {
        debugPrint('⚠️ asset_id still null after resolution — no history');
        if (mounted) setState(() => _isLoadingHistory = false);
        return;
      }

      // 1. All owners from character_ownership
      final ownershipRows = await supabase
          .from('character_ownership')
          .select('owner_email, acquired_at, acquired_via, status, asset_id')
          .eq('asset_id', _assetId!)
          .order('acquired_at', ascending: false);

      for (final row in ownershipRows) {
        emails.add(row['owner_email'] as String);
      }

      // 2. Completed trades involving this character
      final trades = await supabase
          .from('trades')
          .select(
            'proposer_email, receiver_email, offered_character_id, requested_character_id, status, proposed_at, responded_at',
          )
          .or(
            'offered_character_id.eq.${ch.id},requested_character_id.eq.${ch.id}',
          )
          .eq('status', 'accepted')
          .order('responded_at', ascending: false);

      for (final t in trades) {
        emails.add(t['proposer_email'] as String);
        emails.add(t['receiver_email'] as String);
      }

      // 3. Lends for this character
      final lends = await supabase
          .from('lends')
          .select(
            'lender_email, borrower_email, character_id, status, proposed_at, accepted_at, returned_at',
          )
          .eq('character_id', ch.id)
          .inFilter('status', ['active', 'returned'])
          .order('proposed_at', ascending: false);

      for (final l in lends) {
        emails.add(l['lender_email'] as String);
        emails.add(l['borrower_email'] as String);
      }

      // 4. Batch-fetch profiles for all involved users
      final profileMap = <String, Map<String, dynamic>>{};
      if (emails.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select(
              'email, full_name, first_name, last_name, username, avatar_url',
            )
            .inFilter('email', emails.toList());
        for (final p in profiles) {
          profileMap[p['email'] as String] = p;
        }
      }

      // 5. Build timeline: all ownership records
      for (int i = 0; i < ownershipRows.length; i++) {
        final row = ownershipRows[i];
        final ownerEmail = row['owner_email'] as String;
        final isActive = row['status'] == 'active';
        events.add({
          'type': 'owner',
          'email': ownerEmail,
          'date': row['acquired_at'],
          'via': row['acquired_via'] ?? 'acquired',
          'isCurrent': i == 0 && isActive,
          'profile': profileMap[ownerEmail],
        });
      }

      // 6. Add completed trades (most recent first)
      for (final t in trades) {
        final fromEmail = t['proposer_email'] as String;
        final toEmail = t['receiver_email'] as String;
        events.add({
          'type': 'trade',
          'fromEmail': fromEmail,
          'toEmail': toEmail,
          'date': t['responded_at'] ?? t['proposed_at'],
          'fromProfile': profileMap[fromEmail],
          'toProfile': profileMap[toEmail],
        });
      }

      // 7. Add lends
      for (final l in lends) {
        final lenderEmail = l['lender_email'] as String;
        final borrowerEmail = l['borrower_email'] as String;
        events.add({
          'type': 'lend',
          'lenderEmail': lenderEmail,
          'borrowerEmail': borrowerEmail,
          'date': l['accepted_at'] ?? l['proposed_at'],
          'returnedAt': l['returned_at'],
          'status': l['status'],
          'lenderProfile': profileMap[lenderEmail],
          'borrowerProfile': profileMap[borrowerEmail],
        });
      }

      debugPrint('>>> Ownership history: ${events.length} events for ${ch.id}');

      if (mounted) {
        setState(() {
          _ownershipTimeline = events;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('>>> Ownership history load error: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadGameplayVideos() async {
    try {
      final rows = await Supabase.instance.client
          .from('character_gameplay_videos')
          .select('game_name, video_url, thumbnail_url, sort_order')
          .eq('character_id', ch.id)
          .order('sort_order');
      if (mounted) {
        setState(() {
          _gameplayVideos = List<Map<String, dynamic>>.from(rows);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Gameplay videos load failed for ${ch.id}: $e');
    }
  }

  Future<void> _loadCounterpartyProfiles() async {
    final supabase = Supabase.instance.client;

    // Load lend counterparty
    if (isBorrowed && widget.lendInfo != null) {
      final lenderEmail = widget.lendInfo!['lender_email'] as String?;
      if (lenderEmail != null) {
        try {
          final profile = await supabase
              .from('profiles')
              .select(
                'email, full_name, first_name, last_name, username, avatar_url',
              )
              .eq('email', lenderEmail)
              .maybeSingle();
          if (mounted && profile != null) {
            setState(() => _lendCounterpartyProfile = profile);
          }
        } catch (e) {
          debugPrint('⚠️ Lend counterparty load failed: $e');
        }
      }
    }

    if (isLentOut) {
      // For lent-out, we need the borrower — query lends table
      try {
        final lend = await supabase
            .from('lends')
            .select('borrower_email, return_due_at')
            .eq('character_id', ch.id)
            .eq('status', 'active')
            .maybeSingle();
        if (lend != null) {
          final borrowerEmail = lend['borrower_email'] as String;
          final profile = await supabase
              .from('profiles')
              .select(
                'email, full_name, first_name, last_name, username, avatar_url',
              )
              .eq('email', borrowerEmail)
              .maybeSingle();
          if (mounted && profile != null) {
            setState(() {
              _lendCounterpartyProfile = {
                ...profile,
                'return_due_at': lend['return_due_at'],
              };
            });
          }
        }
      } catch (e) {
        debugPrint('⚠️ Lent-out counterparty load failed: $e');
      }
    }

    // Load trade counterparty + full trade details
    if (isPendingTrade && widget.pendingTradeInfo != null) {
      final counterpartyEmail =
          widget.pendingTradeInfo!['counterparty_email'] as String?;
      if (counterpartyEmail != null) {
        try {
          final profile = await supabase
              .from('profiles')
              .select(
                'email, full_name, first_name, last_name, username, avatar_url',
              )
              .eq('email', counterpartyEmail)
              .maybeSingle();
          if (mounted && profile != null) {
            setState(() => _tradeCounterpartyProfile = profile);
          }
        } catch (e) {
          debugPrint('⚠️ Trade counterparty load failed: $e');
        }
      }
      // Load full trade row for character details
      final tradeId = widget.pendingTradeInfo!['trade_id'];
      if (tradeId != null) {
        try {
          final trade = await supabase
              .from('trades')
              .select('*')
              .eq('id', tradeId)
              .maybeSingle();
          if (mounted && trade != null) {
            setState(() => _fullTradeDetails = trade);
            debugPrint('✅ Full trade details loaded: $tradeId');
          }
        } catch (e) {
          debugPrint('⚠️ Full trade details load failed: $e');
        }
      }
    }
  }

  Future<void> _returnBorrowed() async {
    final lendId = widget.lendInfo?['id'] as String?;
    if (lendId == null) {
      _showSnackError('Lend record not found.');
      return;
    }

    final confirmed = await _showConfirmDialog(
      'RETURN CHARACTER',
      'Return ${ch.name} early to ${_profileDisplayName(_lendCounterpartyProfile)}? '
          'You will lose access immediately.',
      confirmText: 'RETURN',
      confirmColor: _lendCyan,
    );
    if (!confirmed) return;

    final result = await LendService.returnEarly(lendId);
    if (result == 'success' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ch.name} returned successfully.'),
          backgroundColor: _lendCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop({'lendResolved': true});
    } else {
      _showSnackError(result);
    }
  }

  Future<void> _recallLend() async {
    final confirmed = await _showConfirmDialog(
      'RECALL CHARACTER',
      'Recall ${ch.name} early? ${_profileDisplayName(_lendCounterpartyProfile)} will be notified.',
      confirmText: 'RECALL',
      confirmColor: Colors.orange.shade400,
    );
    if (!confirmed) return;

    try {
      final supabase = Supabase.instance.client;
      final lend = await supabase
          .from('lends')
          .select('id')
          .eq('character_id', ch.id)
          .eq('status', 'active')
          .maybeSingle();

      if (lend == null) {
        _showSnackError('Active lend not found.');
        return;
      }

      final result = await LendService.recallLend(lend['id'] as String);
      if (result == 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Character recalled!'),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop({'lendResolved': true});
      } else {
        _showSnackError(result ?? 'Recall failed.');
      }
    } catch (e) {
      _showSnackError('Error: $e');
    }
  }

  void _showSnackError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
      );
    }
  }

  String get _currentGameLabel {
    if (_selectedVariationIndex >= 0 &&
        _selectedVariationIndex < ch.gameVariations.length) {
      return ch.gameVariations[_selectedVariationIndex].gameName.toUpperCase();
    }
    return 'ORIGINAL';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _voidBlack,
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Split Pane
  // ═══════════════════════════════════════════════════════════

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Hero image (sticky)
        Expanded(flex: 5, child: _buildHeroSection(isDesktop: true)),
        // Right: Scrollable content
        Expanded(flex: 5, child: _buildContentPanel()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT — Full-bleed scroll
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        // Hero as sliver app bar
        SliverAppBar(
          expandedHeight: 420,
          pinned: true,
          backgroundColor: _voidBlack,
          leading: _buildBackButton(),
          actions: [
            if (!isGuest) ...[
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: NotificationBellWidget(),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildShareButton(),
              ),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroSection(isDesktop: false),
          ),
        ),
        // Content
        SliverToBoxAdapter(child: _buildAllSections()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroSection({required bool isDesktop}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: silhouette or gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _voidBlack,
                _getRarityColor().withValues(alpha: 0.15),
                _voidBlack,
              ],
            ),
          ),
        ),

        // Character image with animated glow
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Center(
              child: Container(
                decoration: owned && !isLentOut && !isPendingTrade
                    ? BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: _neonGreen.withValues(
                              alpha: _glowAnimation.value * 0.3,
                            ),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      )
                    : null,
                child: _buildHeroPageView(),
              ),
            );
          },
        ),

        // Gradient overlay at bottom for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, _voidBlack.withValues(alpha: 0.9)],
              ),
            ),
          ),
        ),

        // Title overlay
        Positioned(
          bottom: isDesktop ? 40 : 20,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game label badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _neonGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _currentGameLabel,
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Character name
              Text(
                ch.name.toUpperCase(),
                style: const TextStyle(
                  color: _pureWhite,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                'THE ${ch.characterClass.toUpperCase()}',
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              // Rarity + IP badge row
              Row(
                children: [
                  _buildBadge(ch.rarity.toUpperCase(), _getRarityColor()),
                  const SizedBox(width: 8),
                  _buildBadge(ch.ip.toUpperCase(), _ironGrey),
                  if (owned && !isLentOut && !isPendingTrade) ...[
                    const SizedBox(width: 8),
                    _buildBadge('OWNED', _neonGreen),
                  ],
                  if (isBorrowed) ...[
                    const SizedBox(width: 8),
                    _buildBadge('BORROWED', _lendCyan),
                  ],
                  if (isLentOut) ...[
                    const SizedBox(width: 8),
                    _buildBadge('LENT OUT', _ironGrey),
                  ],
                  if (isPendingTrade) ...[
                    const SizedBox(width: 8),
                    _buildBadge('TRADE PENDING', _tradeAmber),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Brand logo badge (top-right, responsive) ──────────
        CoBrandLogoBadge(characterId: ch.id),

        // Back button (desktop only — mobile uses SliverAppBar)
        if (isDesktop) Positioned(top: 16, left: 16, child: _buildBackButton()),
      ],
    );
  }

  Widget _buildHeroPageView() {
    // Pages: [original hero, variation 0, variation 1, ...]
    final totalPages = 1 + ch.gameVariations.length;

    return Container(
      width: 280,
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _deepCharcoal,
        border: Border.all(
          color: owned ? _neonGreen.withValues(alpha: 0.3) : _ironGrey,
          width: owned ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Swipeable hero images
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: PageView.builder(
              controller: _heroPageController,
              itemCount: totalPages,
              onPageChanged: (page) {
                setState(() {
                  // Page 0 = original (-1), page 1+ = variation index
                  _selectedVariationIndex = page - 1;
                });
              },
              itemBuilder: (context, page) {
                final imagePath = page == 0
                    ? ch.heroImage
                    : ch.gameVariations[page - 1].characterImage;

                return OgaImage(
                  path: imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  accentColor: _getRarityColor(),
                  fallbackIcon: Icons.person,
                  fallbackIconSize: 64,
                );
              },
            ),
          ),

          // Lock overlay — different states
          if (!canInteract && !isLentOut && !isPendingTrade)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _voidBlack.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: _neonGreen, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          color: _neonGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Lent-out overlay
          if (isLentOut)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: _voidBlack.withValues(alpha: 0.55),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.call_made,
                      color: _pureWhite.withValues(alpha: 0.5),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LENT OUT',
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    if (_lendCounterpartyProfile != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'To ${_profileDisplayName(_lendCounterpartyProfile)}',
                        style: TextStyle(
                          color: _pureWhite.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Trade-pending overlay
          if (isPendingTrade)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: _voidBlack.withValues(alpha: 0.55),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: _tradeAmber.withValues(alpha: 0.7),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TRADE PENDING',
                      style: TextStyle(
                        color: _tradeAmber,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Brand logo badge — always last so it overlays other content
          BrandLogoBadge(characterId: ch.id),

          // Borrowed badge overlay (top-right)
          if (isBorrowed)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _lendCyan.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'BORROWED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (widget.lendInfo?['return_due_at'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatCountdown(
                          widget.lendInfo!['return_due_at'] as String,
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Page indicator dots
          if (totalPages > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) {
                  final isActive = i == (_selectedVariationIndex + 1);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _neonGreen
                          : _pureWhite.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          // Swipe hint arrows (left/right)
          if (ch.gameVariations.isNotEmpty) ...[
            // Left arrow (when not on first page)
            if (_selectedVariationIndex >= 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _heroPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _voidBlack.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: _pureWhite.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            // Right arrow (when not on last page)
            if (_selectedVariationIndex < ch.gameVariations.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _heroPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _voidBlack.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: _pureWhite.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENT PANEL (right side on desktop, below hero on mobile)
  // ═══════════════════════════════════════════════════════════

  Widget _buildContentPanel() {
    return Column(
      children: [
        // Back button row for desktop
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              _buildBackButton(),
              const Spacer(),
              if (!isGuest) ...[
                const NotificationBellWidget(),
                const SizedBox(width: 8),
                _buildShareButton(),
              ],
            ],
          ),
        ),
        Expanded(child: _buildAllSections()),
      ],
    );
  }

  Widget _buildAllSections() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── VIEWING INVITER'S CHARACTER BANNER ─────────
          if (widget.inviterName != null) _buildInviterBanner(),

          // ── STATE BANNERS ──────────────────────────────
          if (isBorrowed) _buildBorrowedInfoCard(),
          if (isLentOut) _buildLentOutInfoCard(),
          if (isPendingTrade) _buildTradePendingInfoCard(),
          if (!canInteract && !isLentOut && !isPendingTrade) _buildLockedCTA(),

          // ── ABOUT ──────────────────────────────────────
          _buildSectionCard(
            title: 'ABOUT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.description,
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                if (ch.lore.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    ch.lore,
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── TRADE / LEND ACTIONS (owned, not lent out, not pending trade) ──
          if (owned && !isGuest && !isLentOut && !isPendingTrade && !isBorrowed)
            _buildOwnerActions(),
          if (owned && !isGuest && !isLentOut && !isPendingTrade && !isBorrowed)
            const SizedBox(height: 20),

          // ── MULTIGAMEVERSE ─────────────────────────────
          _buildSectionCard(
            title: '${ch.name.toUpperCase()} MULTIGAMEVERSE',
            subtitle: '${ch.gameVariations.length} GAMES',
            child: _buildGameVariations(),
            locked: !canInteract,
            lockedMessage: 'Own this character to explore all game versions',
          ),
          const SizedBox(height: 20),

          // ── PORTAL PASS ────────────────────────────────────────
          PortalPassSection(
            characterId: ch.id,
            characterName: ch.name,
            isOwned: owned,
            onViewPass: () => Navigator.pushNamed(
              context,
              '/portal-pass',
              arguments: {'characterId': ch.id},
            ),
          ),
          const SizedBox(height: 20),

          // ── PORTAL PASS SPECIAL REWARD (completion prize) ──────
          SpecialRewardSection(characterId: ch.id, isOwned: owned),
          const SizedBox(height: 20),

          // ── SPECIAL REWARDS ────────────────────────────────────
          _buildSectionCard(
            title: 'SPECIAL REWARDS',
            subtitle: '${ch.specialRewards.length} ITEMS',
            child: _buildSpecialRewards(),
            locked: !canInteract,
            lockedMessage: 'Own this character to unlock rewards',
          ),
          const SizedBox(height: 20),

          // ── OWNERSHIP HISTORY ──────────────────────────
          _buildSectionCard(
            title: 'OWNERSHIP HISTORY',
            subtitle: _isLoadingHistory
                ? '...'
                : '${_ownershipTimeline.where((e) => e['type'] == 'owner').length} OWNERS',
            child: _buildOwnershipHistory(),
          ),
          const SizedBox(height: 20),

          // ── GAMEPLAY ───────────────────────────────────
          if (_gameplayVideos.isNotEmpty)
            _buildSectionCard(
              title: 'GAMEPLAY',
              child: _buildGameplayCarousel(),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BORROWED / LENT-OUT / TRADE-PENDING INFO CARDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildBorrowedInfoCard() {
    final name = _profileDisplayName(_lendCounterpartyProfile);
    final avatarUrl = _lendCounterpartyProfile?['avatar_url'] as String?;
    final returnDate = widget.lendInfo?['return_due_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_lendCyan.withValues(alpha: 0.08), _deepCharcoal],
        ),
        border: Border.all(color: _lendCyan.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined, color: _lendCyan, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'BORROWED CHARACTER',
                  style: TextStyle(
                    color: _lendCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (returnDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _lendCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatCountdown(returnDate),
                    style: TextStyle(
                      color: _lendCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Lender info row
          Row(
            children: [
              _buildHistoryAvatar(avatarUrl, name, true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LENDER',
                      style: TextStyle(
                        color: _lendCyan.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: _pureWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You have full access to this character while borrowed. It will return automatically when the timer expires.',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _returnBorrowed(),
              icon: Icon(Icons.keyboard_return, size: 16, color: _lendCyan),
              label: const Text(
                'RETURN EARLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _lendCyan,
                side: BorderSide(color: _lendCyan.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLentOutInfoCard() {
    final name = _profileDisplayName(_lendCounterpartyProfile);
    final avatarUrl = _lendCounterpartyProfile?['avatar_url'] as String?;
    final returnDate = _lendCounterpartyProfile?['return_due_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _deepCharcoal,
        border: Border.all(color: _ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.call_made,
                color: _pureWhite.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CHARACTER LENT OUT',
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (returnDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _ironGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Returns ${_formatCountdown(returnDate)}',
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Real avatar (or initial fallback)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _tradeAmber.withValues(alpha: 0.3)),
                  color: _voidBlack,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, st) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'A',
                              style: TextStyle(
                                color: _tradeAmber,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: TextStyle(
                              color: _tradeAmber,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BORROWER',
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This character is temporarily lent out. Features are locked until it returns. Trading and re-lending are disabled.',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _recallLend(),
              icon: Icon(Icons.replay, size: 16, color: Colors.orange.shade400),
              label: Text(
                'RECALL EARLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.orange.shade400,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradePendingInfoCard() {
    final name = _profileDisplayName(_tradeCounterpartyProfile);
    final avatarUrl = _tradeCounterpartyProfile?['avatar_url'] as String?;
    final role = widget.pendingTradeInfo?['role'] as String?;
    final proposedAt = widget.pendingTradeInfo?['proposed_at'] as String?;
    final isProposer = role == 'proposer';

    // Character IDs from full trade details
    final offeredCharId = _fullTradeDetails?['offered_character_id'] as String?;
    final requestedCharId =
        _fullTradeDetails?['requested_character_id'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_tradeAmber.withValues(alpha: 0.06), _deepCharcoal],
        ),
        border: Border.all(color: _tradeAmber.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: _tradeAmber, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'TRADE PENDING',
                  style: TextStyle(
                    color: _tradeAmber,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Counterparty row
          Row(
            children: [
              _buildHistoryAvatar(avatarUrl, name, false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProposer ? 'TRADE OFFERED TO' : 'TRADE PROPOSED BY',
                      style: TextStyle(
                        color: _tradeAmber.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: _pureWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (proposedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Proposed ${_formatDateStr(proposedAt)}',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ],

          // ── Trade summary (what's being exchanged) ──
          // ── Trade summary (what's being exchanged) ──
          if (_fullTradeDetails != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _voidBlack.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _tradeAmber.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isProposer ? 'YOU GIVE' : 'YOU RECEIVE',
                          style: TextStyle(
                            color: _tradeAmber.withValues(alpha: 0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTradeCharCard(
                          isProposer ? offeredCharId : requestedCharId,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_horiz,
                      color: _tradeAmber.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isProposer ? 'YOU RECEIVE' : 'YOU GIVE',
                          style: TextStyle(
                            color: _tradeAmber.withValues(alpha: 0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTradeCharCard(
                          isProposer ? requestedCharId : offeredCharId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Action Buttons ──
          if (_isTradeActionLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: _tradeAmber,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (isProposer)
            // PROPOSER: Can revoke
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _revokeTradeOffer(),
                icon: const Icon(Icons.undo, size: 14),
                label: const Text(
                  'REVOKE TRADE OFFER',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else ...[
            // RECEIVER: Can accept or decline
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptTrade(),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _neonGreen,
                      foregroundColor: _voidBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _declineTrade(),
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: const Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'DECLINE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: BorderSide(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════
  // TRADE ACTIONS (revoke / accept / decline)
  // ═══════════════════════════════════════════════════════════

  /// Look up character name from hardcoded data by ID
  String _charNameFromId(String? charId) {
    if (charId == null) return 'Unknown';
    // Check current character first
    if (ch.id == charId) return ch.name;
    // Search all characters (from OGACharacter.allCharacters)
    try {
      final match = OGACharacter.allCharacters.firstWhere(
        (c) => c.id == charId,
      );
      return match.name;
    } catch (_) {
      // Fallback: capitalize the ID
      return charId.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Build a mini character card for the trade summary.
  Widget _buildTradeCharCard(String? charId) {
    final character = charId != null ? OGACharacter.fromId(charId) : null;
    final charName = _charNameFromId(charId);
    final heroImg = character?.heroImage ?? '';

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _tradeAmber.withValues(alpha: 0.2)),
            color: _deepCharcoal,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: heroImg.isNotEmpty
                ? Image.network(
                    OgaStorage.resolve(heroImg),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, e, st) => Center(
                      child: Icon(
                        Icons.swap_horiz,
                        color: _tradeAmber.withValues(alpha: 0.3),
                        size: 24,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.swap_horiz,
                      color: _tradeAmber.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          charName,
          style: const TextStyle(
            color: _pureWhite,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _revokeTradeOffer() async {
    final tradeId = widget.pendingTradeInfo?['trade_id'];
    if (tradeId == null) return;

    final confirmed = await _showConfirmDialog(
      'REVOKE TRADE OFFER',
      'Are you sure you want to cancel this trade offer? '
          '${ch.name} will be unlocked for other actions.',
      confirmText: 'REVOKE',
      confirmColor: const Color(0xFFEF4444),
    );
    if (!confirmed) return;

    setState(() => _isTradeActionLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('trades')
          .update({
            'status': 'revoked',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tradeId);

      // Notify counterparty
      final counterpartyEmail =
          widget.pendingTradeInfo?['counterparty_email'] as String?;
      if (counterpartyEmail != null) {
        await supabase.from('notifications').insert({
          'recipient_email': counterpartyEmail,
          'type': 'trade_revoked',
          'message': 'Trade offer for ${ch.name} was revoked.',
          'related_character_id': ch.id,
          'metadata': {'trade_id': tradeId},
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _deepCharcoal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: _neonGreen.withValues(alpha: 0.3)),
            ),
            content: const Text(
              'Trade offer revoked.',
              style: TextStyle(color: _pureWhite),
            ),
          ),
        );
        Navigator.of(context).pop({'tradeResolved': true});
      }
    } catch (e) {
      debugPrint('⚠️ Revoke trade failed: $e');
      if (mounted) {
        setState(() => _isTradeActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Failed to revoke trade: $e',
              style: const TextStyle(color: _pureWhite),
            ),
          ),
        );
      }
    }
  }

  Future<void> _acceptTrade() async {
    final tradeId = widget.pendingTradeInfo?['trade_id'];
    if (tradeId == null) return;

    final confirmed = await _showConfirmDialog(
      'ACCEPT TRADE',
      'You will trade ${ch.name} for ${_charNameFromId(_fullTradeDetails?['offered_character_id'] as String?)}. '
          'This action cannot be undone.',
      confirmText: 'ACCEPT TRADE',
      confirmColor: _neonGreen,
    );
    if (!confirmed) return;

    setState(() => _isTradeActionLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Use RPC to execute the trade atomically (swap ownership)
      await supabase.rpc('execute_trade', params: {'p_trade_id': tradeId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _deepCharcoal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: _neonGreen.withValues(alpha: 0.3)),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: _neonGreen, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Trade completed!',
                    style: TextStyle(
                      color: _pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).pop({'tradeResolved': true});
      }
    } catch (e) {
      debugPrint('⚠️ Accept trade failed: $e');
      if (mounted) {
        setState(() => _isTradeActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Failed to accept trade: $e',
              style: const TextStyle(color: _pureWhite),
            ),
          ),
        );
      }
    }
  }

  Future<void> _declineTrade() async {
    final tradeId = widget.pendingTradeInfo?['trade_id'];
    if (tradeId == null) return;

    final confirmed = await _showConfirmDialog(
      'DECLINE TRADE',
      'Decline this trade offer? ${ch.name} will be unlocked for other actions.',
      confirmText: 'DECLINE',
      confirmColor: const Color(0xFFEF4444),
    );
    if (!confirmed) return;

    setState(() => _isTradeActionLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('trades')
          .update({
            'status': 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tradeId);

      // Notify proposer
      final counterpartyEmail =
          widget.pendingTradeInfo?['counterparty_email'] as String?;
      if (counterpartyEmail != null) {
        await supabase.from('notifications').insert({
          'recipient_email': counterpartyEmail,
          'type': 'trade_declined',
          'message': 'Your trade offer for ${ch.name} was declined.',
          'related_character_id': ch.id,
          'metadata': {'trade_id': tradeId},
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _deepCharcoal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _ironGrey),
            ),
            content: const Text(
              'Trade declined.',
              style: TextStyle(color: _pureWhite),
            ),
          ),
        );
        Navigator.of(context).pop({'tradeResolved': true});
      }
    } catch (e) {
      debugPrint('⚠️ Decline trade failed: $e');
      if (mounted) {
        setState(() => _isTradeActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Failed to decline trade: $e',
              style: const TextStyle(color: _pureWhite),
            ),
          ),
        );
      }
    }
  }

  /// Reusable confirmation dialog for destructive actions
  Future<bool> _showConfirmDialog(
    String title,
    String message, {
    String confirmText = 'CONFIRM',
    Color confirmColor = _neonGreen,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: _voidBlack.withValues(alpha: 0.8),
          builder: (context) => AlertDialog(
            backgroundColor: _deepCharcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _ironGrey),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: _pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: confirmColor == _neonGreen
                      ? _voidBlack
                      : _pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ═══════════════════════════════════════════════════════════
  // CHARACTER LOCKED CTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildLockedCTA() {
    // Determine if we're viewing a friend's owned character
    final bool isFriendOwned =
        widget.ownerEmail != null && widget.ownerEmail!.isNotEmpty && !isGuest;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_neonGreen.withValues(alpha: 0.08), _deepCharcoal],
        ),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: _neonGreen, size: 32),
          const SizedBox(height: 12),
          const Text(
            'CHARACTER LOCKED',
            style: TextStyle(
              color: _neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFriendOwned
                ? 'This character belongs to ${widget.ownerName ?? 'a friend'}. '
                      'Request a trade, lend, or buy it.'
                : 'Acquire this OGA to unlock the full experience — '
                      'game variations, Portal Pass, rewards, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isGuest) return;
                    if (widget.ownerEmail != null &&
                        widget.ownerEmail!.isNotEmpty) {
                      GetCharacterModal.show(
                        context,
                        characterId: ch.id,
                        ownerEmail: widget.ownerEmail!,
                        ownerName: widget.ownerName ?? 'Friend',
                        characterName: ch.name,
                      );
                    } else {
                      _showMarketplaceComingSoon();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: _voidBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'GET THIS CHARACTER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/portal-pass'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _pureWhite,
                  side: const BorderSide(color: _ironGrey),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'VIEW PASS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Marketplace coming soon bottom sheet (shared by locked CTA and locked overlays)
  void _showMarketplaceComingSoon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Color(0xFF2C2C2C))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.lock_outline, color: const Color(0xFF39FF14), size: 36),
            const SizedBox(height: 12),
            Text(
              '${ch.name.toUpperCase()} IS LOCKED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The marketplace is coming soon. In the meantime, find friends who own this character and propose a trade.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  FriendsWhoOwnModal.show(context, ch);
                },
                icon: const Icon(Icons.people_outline, size: 16),
                label: const Text(
                  'FIND FRIENDS WHO OWN THIS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF39FF14),
                  side: const BorderSide(color: Color(0xFF39FF14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'MARKETPLACE COMING SOON',
              style: TextStyle(
                color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INVITER CONTEXT BANNER
  // ═══════════════════════════════════════════════════════════

  Widget _buildInviterBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _deepCharcoal,
        border: Border.all(color: _ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: _neonGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIEWING ${widget.inviterName!.toUpperCase()}\'S CHARACTER',
                      style: const TextStyle(
                        color: _pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Want this character? Request a trade.',
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _deepCharcoal,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    content: const Text(
                      'Trading coming soon! Stay tuned.',
                      style: TextStyle(color: _pureWhite),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text(
                'REQUEST TRADE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonGreen,
                foregroundColor: _voidBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION CARD WRAPPER
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
    bool locked = false,
    String lockedMessage = '',
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
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
                      subtitle,
                      style: TextStyle(
                        color: _neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content — with optional lock overlay
          if (locked)
            _buildLockedOverlay(child, lockedMessage)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildLockedOverlay(Widget child, String message) {
    return Stack(
      children: [
        // Blurred/dimmed content preview
        Opacity(
          opacity: 0.25,
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
          ),
        ),
        // Lock overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: _voidBlack.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: _neonGreen, size: 28),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if (isGuest) return;
                    if (widget.ownerEmail != null &&
                        widget.ownerEmail!.isNotEmpty) {
                      GetCharacterModal.show(
                        context,
                        characterId: ch.id,
                        ownerEmail: widget.ownerEmail!,
                        ownerName: widget.ownerName ?? 'Friend',
                        characterName: ch.name,
                      );
                    } else {
                      _showMarketplaceComingSoon();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _neonGreen.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isGuest ? 'SIGN UP TO UNLOCK' : 'GET THIS CHARACTER',
                      style: TextStyle(
                        color: _neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
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
  // GAME VARIATIONS (MULTIGAMEVERSE) — Sprint 9A: Tap-to-Expand
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameVariations() {
    if (ch.gameVariations.isEmpty) {
      return Container(
        height: 200, // <-- Added height to match the carousel
        alignment: Alignment.centerLeft,
        child: Text(
          'No game variations available yet.',
          style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
        ),
      );
    }
    // ... rest of your existing code

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Horizontal Carousel ─────────────────────────
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ch.gameVariations.length,
            itemBuilder: (context, index) {
              final variation = ch.gameVariations[index];
              final isSelected = _selectedVariationIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariationIndex = isSelected ? -1 : index;
                  });
                  final targetPage = isSelected ? 0 : index + 1;
                  if (_heroPageController.hasClients) {
                    _heroPageController.animateToPage(
                      targetPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 140,
                  margin: EdgeInsets.only(
                    right: index < ch.gameVariations.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _voidBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _neonGreen
                          : _ironGrey.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _neonGreen.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: OgaImage(
                                path: variation.characterImage,
                                fit: BoxFit.cover,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                                accentColor: _getRarityColor(),
                                fallbackIcon: Icons.videogame_asset,
                                fallbackIconSize: 32,
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: _neonGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.expand_more,
                                    color: _voidBlack,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _neonGreen.withValues(alpha: 0.05)
                              : _deepCharcoal,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(11),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: variation.gameIcon.isNotEmpty
                                      ? OgaImage(
                                          path: variation.gameIcon,
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.sports_esports,
                                          fallbackIconSize: 10,
                                        )
                                      : Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _ironGrey,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.sports_esports,
                                            size: 10,
                                            color: _pureWhite.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    variation.gameName.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? _neonGreen
                                          : _pureWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              variation.description,
                              style: TextStyle(
                                color: _pureWhite.withValues(alpha: 0.4),
                                fontSize: 9,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Expanded Detail Panel ───────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              _selectedVariationIndex >= 0 &&
                  _selectedVariationIndex < ch.gameVariations.length
              ? _buildExpandedVariationDetail(
                  ch.gameVariations[_selectedVariationIndex],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildExpandedVariationDetail(GameVariation variation) {
    return Container(
      key: ValueKey('variation_${variation.gameId}'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voidBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: _neonGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: variation.gameIcon.isNotEmpty
                    ? OgaImage(
                        path: variation.gameIcon,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.sports_esports,
                        fallbackIconSize: 14,
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _ironGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.sports_esports,
                          size: 14,
                          color: _pureWhite.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  variation.gameName.toUpperCase(),
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (variation.engineName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _deepCharcoal,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    variation.engineName.toUpperCase(),
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedVariationIndex = -1);
                  if (_heroPageController.hasClients) {
                    _heroPageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _ironGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close,
                    color: _pureWhite.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 360;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVariationRender(variation),
                    const SizedBox(width: 16),
                    Expanded(child: _buildVariationInfo(variation)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildVariationRender(variation)),
                    const SizedBox(height: 14),
                    _buildVariationInfo(variation),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVariationRender(GameVariation variation) {
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _deepCharcoal,
        border: Border.all(color: _neonGreen.withValues(alpha: 0.15), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: OgaImage(
              path: variation.characterImage,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(11),
              accentColor: _getRarityColor(),
              fallbackIcon: Icons.videogame_asset,
              fallbackIconSize: 48,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _voidBlack.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variation.gameName.toUpperCase(),
                style: const TextStyle(
                  color: _neonGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationInfo(GameVariation variation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ch.name.toUpperCase()} IN ${variation.gameName.toUpperCase()}',
          style: TextStyle(
            color: _neonGreen,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        if (variation.description.isNotEmpty)
          Text(
            variation.description,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (variation.engineName.isNotEmpty)
              _buildInfoChip(Icons.memory, variation.engineName),
            _buildInfoChip(Icons.videogame_asset, variation.gameName),
            _buildInfoChip(Icons.category, ch.ip),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text(
              'VIEW IN GAME',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 11,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _neonGreen,
              side: BorderSide(color: _neonGreen.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _pureWhite.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TRADE / LEND ACTIONS (owned characters)
  // ═══════════════════════════════════════════════════════════

  Widget _buildOwnerActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIONS',
            style: TextStyle(
              color: _pureWhite,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Trade or lend ${ch.name} to a friend.',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isBorrowed
                      ? null
                      : () => TradeProposalModal.show(
                          context,
                          characterId: ch.id,
                        ),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text(
                    'TRADE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: _voidBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isBorrowed
                      ? null
                      : () =>
                            LendProposalModal.show(context, characterId: ch.id),
                  icon: Icon(
                    Icons.handshake_outlined,
                    size: 18,
                    color: const Color(0xFF00BCD4),
                  ),
                  label: const Text(
                    'LEND',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00BCD4),
                    side: const BorderSide(color: Color(0xFF00BCD4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildProgressBar(double percent, int current, int max) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LEVEL $current',
              style: const TextStyle(
                color: _neonGreen,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: _ironGrey,
            valueColor: const AlwaysStoppedAnimation(_neonGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneTrack(PortalPass pass) {
    final sortedRewards = [...pass.rewards]
      ..sort((a, b) => a.levelRequired.compareTo(b.levelRequired));
    return SizedBox(
      height: 100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final nodeCount = sortedRewards.length;
          if (nodeCount == 0) return const SizedBox.shrink();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _ironGrey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                left: 0,
                child: Container(
                  height: 3,
                  width: trackWidth * pass.progressPercent,
                  decoration: BoxDecoration(
                    color: _neonGreen,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: _neonGreen.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              ...List.generate(nodeCount, (index) {
                final reward = sortedRewards[index];
                final position = nodeCount == 1
                    ? trackWidth / 2
                    : (trackWidth - 40) * (index / (nodeCount - 1)) + 20;
                final isReached = pass.currentLevel >= reward.levelRequired;
                return Positioned(
                  left: position - 20,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => _showRewardDetail(context, reward, isReached),
                    child: SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Text(
                            'LVL ${reward.levelRequired}',
                            style: TextStyle(
                              color: isReached
                                  ? _neonGreen
                                  : _pureWhite.withValues(alpha: 0.3),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isReached
                                  ? const Color(0xFF1A3A14)
                                  : _deepCharcoal,
                              border: Border.all(
                                color: isReached
                                    ? _neonGreen
                                    : _ironGrey.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: isReached
                                  ? [
                                      BoxShadow(
                                        color: _neonGreen.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isReached
                                  ? const Icon(
                                      Icons.check,
                                      color: _neonGreen,
                                      size: 14,
                                    )
                                  : Icon(
                                      Icons.lock_outline,
                                      color: _neonGreen.withValues(alpha: 0.5),
                                      size: 12,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reward.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isReached
                                  ? _pureWhite.withValues(alpha: 0.8)
                                  : _pureWhite.withValues(alpha: 0.3),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showRewardDetail(
    BuildContext context,
    PortalPassReward reward,
    bool isUnlocked,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _deepCharcoal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isUnlocked ? _neonGreen.withValues(alpha: 0.3) : _ironGrey,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _ironGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? _neonGreen.withValues(alpha: 0.1)
                    : _voidBlack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnlocked
                      ? _neonGreen.withValues(alpha: 0.4)
                      : _ironGrey,
                ),
              ),
              child: OgaImage(
                path: reward.image,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(14),
                accentColor: isUnlocked ? _neonGreen : _pureWhite,
                fallbackIcon: Icons.card_giftcard,
                fallbackIconSize: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              reward.name.toUpperCase(),
              style: const TextStyle(
                color: _pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? _neonGreen.withValues(alpha: 0.15)
                    : _ironGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isUnlocked
                    ? 'UNLOCKED'
                    : 'UNLOCKS AT LEVEL ${reward.levelRequired}',
                style: TextStyle(
                  color: isUnlocked
                      ? _neonGreen
                      : _pureWhite.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 20 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveTaskItem(PortalPassTask task) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _deepCharcoal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: task.isCompleted
                        ? _neonGreen.withValues(alpha: 0.3)
                        : _ironGrey,
                  ),
                ),
                duration: const Duration(seconds: 2),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: _pureWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.isCompleted
                          ? 'Completed! +${task.xpReward} XP earned'
                          : '${task.currentProgress}/${task.targetProgress} — ${task.xpReward} XP reward',
                      style: TextStyle(
                        color: task.isCompleted
                            ? _neonGreen
                            : _pureWhite.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _voidBlack.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: task.isCompleted
                    ? _neonGreen.withValues(alpha: 0.3)
                    : _ironGrey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted
                        ? _neonGreen.withValues(alpha: 0.15)
                        : _ironGrey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: task.isCompleted ? _neonGreen : _ironGrey,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: _neonGreen, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? _pureWhite.withValues(alpha: 0.5)
                              : _pureWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            task.targetGame.toUpperCase(),
                            style: TextStyle(
                              color: _neonGreen.withValues(alpha: 0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${task.xpReward} XP',
                            style: TextStyle(
                              color: _pureWhite.withValues(alpha: 0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!task.isCompleted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${task.currentProgress}/${task.targetProgress}',
                        style: const TextStyle(
                          color: _pureWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: task.progressPercent,
                            minHeight: 3,
                            backgroundColor: _ironGrey,
                            valueColor: const AlwaysStoppedAnimation(
                              _neonGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: _pureWhite.withValues(alpha: 0.2),
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SPECIAL REWARDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSpecialRewards() {
    if (ch.specialRewards.isEmpty) {
      return Container(
        height: 140, // <-- Added height to match the list view below
        alignment: Alignment.centerLeft, // Keeps text aligned properly
        child: Text(
          'No special rewards yet.',
          style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ch.specialRewards.length,
        itemBuilder: (context, index) {
          final reward = ch.specialRewards[index];
          return Container(
            width: 120,
            margin: EdgeInsets.only(
              right: index < ch.specialRewards.length - 1 ? 12 : 0,
            ),
            decoration: BoxDecoration(
              color: _voidBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: reward.isUnlocked
                    ? _neonGreen.withValues(alpha: 0.3)
                    : _ironGrey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: OgaImage(
                    path: reward.image,
                    fit: BoxFit.contain,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    accentColor: _getRarityColorForString(reward.rarity),
                    fallbackIcon: Icons.auto_awesome,
                    fallbackIconSize: 28,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        reward.name.toUpperCase(),
                        style: const TextStyle(
                          color: _pureWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reward.rarity.toUpperCase(),
                        style: TextStyle(
                          color: _getRarityColorForString(reward.rarity),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // OWNERSHIP HISTORY
  // ═══════════════════════════════════════════════════════════

  Widget _buildOwnershipHistory() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: _neonGreen)),
      );
    }

    if (_ownershipTimeline.isEmpty && ch.ownershipHistory.isEmpty) {
      return Text(
        'No ownership history recorded.',
        style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
      );
    }

    if (_ownershipTimeline.isEmpty) return _buildMockOwnershipHistory();

    // Filter to owners only
    final owners = _ownershipTimeline
        .where((e) => e['type'] == 'owner')
        .toList();
    final activities = _ownershipTimeline
        .where((e) => e['type'] != 'owner')
        .toList();

    if (owners.isEmpty) {
      return Text(
        'No ownership history recorded.',
        style: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
      );
    }

    // Truncation logic: show first 5 + separator + first owner
    final bool needsTruncation = owners.length > 6 && !_isHistoryExpanded;
    List<Map<String, dynamic>> displayOwners;

    if (needsTruncation) {
      displayOwners = [
        ...owners.sublist(0, 5),
        {'type': 'separator', 'hiddenCount': owners.length - 6},
        owners.last,
      ];
    } else {
      displayOwners = owners;
    }

    return Column(
      children: [
        ...displayOwners.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final isLast = index == displayOwners.length - 1;

          if (event['type'] == 'separator') {
            return GestureDetector(
              onTap: () => setState(() => _isHistoryExpanded = true),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Column(
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _ironGrey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'SHOW ALL ${owners.length} OWNERS',
                      style: TextStyle(
                        color: _neonGreen.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.expand_more,
                      color: _neonGreen.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }

          final isCurrent = event['isCurrent'] == true;

          return _ExpandableOwnerRow(
            event: event,
            activities: _getActivitiesForOwner(event, activities),
            isCurrent: isCurrent,
            isFirst: index == 0,
            isLast: isLast,
          );
        }),
        if (_isHistoryExpanded && owners.length > 6)
          GestureDetector(
            onTap: () => setState(() => _isHistoryExpanded = false),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.expand_less,
                    color: _neonGreen.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SHOW LESS',
                    style: TextStyle(
                      color: _neonGreen.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Find activities (trades/lends) associated with a specific owner
  List<Map<String, dynamic>> _getActivitiesForOwner(
    Map<String, dynamic> ownerEvent,
    List<Map<String, dynamic>> allActivities,
  ) {
    final email = ownerEvent['email'] as String?;
    if (email == null) return [];
    return allActivities.where((a) {
      if (a['type'] == 'trade')
        return a['fromEmail'] == email || a['toEmail'] == email;
      if (a['type'] == 'lend')
        return a['lenderEmail'] == email || a['borrowerEmail'] == email;
      return false;
    }).toList();
  }

  Widget _buildHistoryAvatar(String? avatarUrl, String name, bool isCurrent) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? _neonGreen : _ironGrey,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitialCircle(initial),
              )
            : _buildInitialCircle(initial),
      ),
    );
  }

  Widget _buildInitialCircle(String initial) {
    return Container(
      width: 36,
      height: 36,
      color: _deepCharcoal,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _neonGreen,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _profileDisplayName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Unknown';
    final first = profile['first_name'] as String? ?? '';
    final last = profile['last_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final full = profile['full_name'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    if (username.isNotEmpty) return '@$username';
    if (full.isNotEmpty) return full;
    return profile['email'] as String? ?? 'Unknown';
  }

  String _formatDateStr(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return _formatDate(dt);
    } catch (_) {
      return dateStr;
    }
  }

  /// Fallback: renders mock ownership data from OGACharacter model
  Widget _buildMockOwnershipHistory() {
    final owners = ch.ownershipHistory.reversed.toList();
    return Column(
      children: owners.asMap().entries.map((entry) {
        final index = entry.key;
        final owner = entry.value;
        final isLast = index == owners.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: owner.isCurrent
                            ? _neonGreen.withValues(alpha: 0.2)
                            : _voidBlack,
                        border: Border.all(
                          color: owner.isCurrent
                              ? _neonGreen
                              : _ironGrey.withValues(alpha: 0.5),
                          width: owner.isCurrent ? 2.5 : 1.5,
                        ),
                        boxShadow: owner.isCurrent
                            ? [
                                BoxShadow(
                                  color: _neonGreen.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: owner.isCurrent
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _neonGreen,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: _ironGrey.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: owner.isCurrent
                        ? _neonGreen.withValues(alpha: 0.04)
                        : _voidBlack.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: owner.isCurrent
                          ? _neonGreen.withValues(alpha: 0.2)
                          : _ironGrey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      OgaAvatarImage(
                        url: owner.avatarUrl,
                        size: 36,
                        fallbackLetter: owner.username.length > 1
                            ? owner.username[1]
                            : '?',
                        borderColor: owner.isCurrent ? _neonGreen : _ironGrey,
                        borderWidth: owner.isCurrent ? 1.5 : 0,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    owner.username,
                                    style: TextStyle(
                                      color: owner.isCurrent
                                          ? _pureWhite
                                          : _pureWhite.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (owner.isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _neonGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        color: _neonGreen,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  owner.isCurrent
                                      ? Icons.verified
                                      : Icons.swap_horiz,
                                  size: 12,
                                  color: owner.isCurrent
                                      ? _neonGreen.withValues(alpha: 0.5)
                                      : _pureWhite.withValues(alpha: 0.25),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  owner.isCurrent
                                      ? 'Acquired ${_formatDate(owner.ownedFrom)}'
                                      : '${_formatDate(owner.ownedFrom)} — ${_formatDate(owner.ownedUntil!)}',
                                  style: TextStyle(
                                    color: _pureWhite.withValues(alpha: 0.3),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GAMEPLAY — per-game video carousel
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGameplayCarousel() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _gameplayVideos.length,
        itemBuilder: (context, index) {
          final video = _gameplayVideos[index];
          final gameName = (video['game_name'] as String? ?? '').toUpperCase();
          final videoUrl = video['video_url'] as String? ?? '';
          final thumbUrl = video['thumbnail_url'] as String?;
          final isLast = index == _gameplayVideos.length - 1;

          return GestureDetector(
            onTap: () => _openVideoLightbox(
              context,
              videoUrl,
              gameName,
              thumbnailUrl: thumbUrl,
            ),
            child: Container(
              width: 260,
              margin: EdgeInsets.only(right: isLast ? 0 : 12),
              decoration: BoxDecoration(
                color: _voidBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ironGrey.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  if (thumbUrl != null)
                    Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: _deepCharcoal),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _neonGreen.withValues(alpha: 0.08),
                            _voidBlack,
                          ],
                        ),
                      ),
                    ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _voidBlack.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  // Play button
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _neonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _neonGreen.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                  // Game label bottom-left
                  Positioned(
                    bottom: 12,
                    left: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          gameName,
                          style: const TextStyle(
                            color: _pureWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ch.name.toUpperCase()} GAMEPLAY',
                          style: TextStyle(
                            color: _neonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fullscreen icon top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _voidBlack.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        color: _pureWhite.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openVideoLightbox(
    BuildContext context,
    String videoUrl,
    String label, {
    String? thumbnailUrl,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: _voidBlack.withValues(alpha: 0.95),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: _VideoLightbox(
            videoUrl: videoUrl,
            label: label,
            thumbnailUrl: thumbnailUrl,
          ),
        ),
      ),
    );
  }

  Widget _buildGameplayGallery() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ch.gameplayMedia.length,
        itemBuilder: (context, index) {
          final media = ch.gameplayMedia[index];
          return GestureDetector(
            onTap: () => _openLightbox(context, index),
            child: Container(
              width: 240,
              margin: EdgeInsets.only(
                right: index < ch.gameplayMedia.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                color: _voidBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ironGrey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        OgaImage(
                          path: media.imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          accentColor: _neonGreen,
                          fallbackIcon: Icons.image,
                          fallbackIconSize: 40,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _voidBlack.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.fullscreen,
                              color: _pureWhite.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _voidBlack.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}/${ch.gameplayMedia.length}',
                              style: TextStyle(
                                color: _pureWhite.withValues(alpha: 0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.gameName.toUpperCase(),
                          style: TextStyle(
                            color: _neonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          media.caption,
                          style: TextStyle(
                            color: _pureWhite.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: _voidBlack.withValues(alpha: 0.95),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _GameplayLightbox(
            media: ch.gameplayMedia,
            initialIndex: initialIndex,
            animation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITY WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _deepCharcoal.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.arrow_back, color: _pureWhite, size: 18),
      ),
    );
  }

  Widget _buildShareButton() {
    return IconButton(
      onPressed: _shareCharacter,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _deepCharcoal.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.share, color: _pureWhite, size: 18),
      ),
    );
  }

  Future<void> _shareCharacter() async {
    // === INVITE QUOTA CHECK (Sprint 11A) ===
    final quota = await InviteService.getInviteQuota();
    if (!quota.canSend) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'INVITE LIMIT REACHED (${quota.displayText})',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }
    if (_userInviteCode == null && !_isFetchingInviteCode) {
      _isFetchingInviteCode = true;
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final response = await Supabase.instance.client
              .from('profiles')
              .select('invite_code')
              .eq('email', user.email!)
              .maybeSingle();
          _userInviteCode = response?['invite_code'] as String?;
          debugPrint('🔗 Fetched invite code: $_userInviteCode');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching invite code: $e');
      } finally {
        _isFetchingInviteCode = false;
      }
    }

    if (_userInviteCode == null || _userInviteCode!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _deepCharcoal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _ironGrey),
            ),
            content: const Text(
              'Unable to generate share link. Try again.',
              style: TextStyle(color: _pureWhite),
            ),
          ),
        );
      }
      return;
    }

    final shareUrl =
        'https://oga.oneearthrising.com/invite/$_userInviteCode/${ch.id}';
    await Clipboard.setData(ClipboardData(text: shareUrl));

    InviteService.recordShare(
      inviteCode: _userInviteCode!,
      characterId: widget.character.id,
    );
    AnalyticsService.trackShareTapped();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _deepCharcoal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _neonGreen.withValues(alpha: 0.3)),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: _neonGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LINK COPIED!',
                      style: TextStyle(
                        color: _neonGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share ${ch.name} with friends',
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == _ironGrey ? _pureWhite.withValues(alpha: 0.7) : color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Color Helpers ────────────────────────────────────────

  Color _getRarityColor() => _getRarityColorForString(ch.rarity);

  Color _getRarityColorForString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return const Color(0xFFAB47BC);
      case 'rare':
        return const Color(0xFF42A5F5);
      default:
        return _ironGrey;
    }
  }

  String _formatCountdown(String returnDateStr) {
    try {
      final returnDate = DateTime.parse(returnDateStr);
      final diff = returnDate.difference(DateTime.now());
      if (diff.isNegative) return 'OVERDUE';
      if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h left';
      if (diff.inHours > 0)
        return '${diff.inHours}h ${diff.inMinutes % 60}m left';
      return '${diff.inMinutes}m left';
    } catch (_) {
      return '';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// ANIMATED BUILDER HELPER
// ═══════════════════════════════════════════════════════════════════

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
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXPANDABLE OWNER ROW — Ownership History
// ═══════════════════════════════════════════════════════════════════

class _ExpandableOwnerRow extends StatefulWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> activities;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;

  const _ExpandableOwnerRow({
    required this.event,
    required this.activities,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_ExpandableOwnerRow> createState() => _ExpandableOwnerRowState();
}

class _ExpandableOwnerRowState extends State<_ExpandableOwnerRow> {
  bool _isExpanded = false;

  String _profileName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Unknown';
    final first = profile['first_name'] as String? ?? '';
    final last = profile['last_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final full = profile['full_name'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    if (username.isNotEmpty) return '@$username';
    if (full.isNotEmpty) return full;
    return profile['email'] as String? ?? 'Unknown';
  }

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.event['profile'] as Map<String, dynamic>?;
    final name = _profileName(profile);
    final avatarUrl = profile?['avatar_url'] as String?;
    final dateStr = widget.event['date'] as String?;
    final via = widget.event['via'] as String? ?? 'acquired';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isFirst
                        ? _neonGreen.withValues(alpha: 0.2)
                        : _voidBlack,
                    border: Border.all(
                      color: widget.isFirst
                          ? _neonGreen
                          : _ironGrey.withValues(alpha: 0.5),
                      width: widget.isFirst ? 2.5 : 1.5,
                    ),
                    boxShadow: widget.isFirst
                        ? [
                            BoxShadow(
                              color: _neonGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: widget.isFirst
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _neonGreen,
                            ),
                          ),
                        )
                      : null,
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _ironGrey.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          // Owner card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
              child: Column(
                children: [
                  // Main row (tappable)
                  GestureDetector(
                    onTap: widget.activities.isNotEmpty
                        ? () => setState(() => _isExpanded = !_isExpanded)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isCurrent
                            ? _neonGreen.withValues(alpha: 0.04)
                            : _voidBlack.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(10),
                          bottom: _isExpanded
                              ? Radius.zero
                              : const Radius.circular(10),
                        ),
                        border: Border.all(
                          color: widget.isCurrent
                              ? _neonGreen.withValues(alpha: 0.2)
                              : _ironGrey.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isCurrent
                                    ? _neonGreen
                                    : _ironGrey,
                                width: widget.isCurrent ? 1.5 : 1,
                              ),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _initialCircle(initial),
                                    )
                                  : _initialCircle(initial),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          color: widget.isCurrent
                                              ? _pureWhite
                                              : _pureWhite.withValues(
                                                  alpha: 0.6,
                                                ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.isCurrent
                                            ? _neonGreen.withValues(alpha: 0.15)
                                            : _ironGrey.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        widget.isCurrent
                                            ? 'CURRENT'
                                            : 'PAST OWNER',
                                        style: TextStyle(
                                          color: widget.isCurrent
                                              ? _neonGreen
                                              : _pureWhite.withValues(
                                                  alpha: 0.3,
                                                ),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: _neonGreen.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr != null
                                          ? '${via[0].toUpperCase()}${via.substring(1)} ${_fmtDate(dateStr)}'
                                          : '${via[0].toUpperCase()}${via.substring(1)}',
                                      style: TextStyle(
                                        color: _pureWhite.withValues(
                                          alpha: 0.3,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (widget.activities.isNotEmpty)
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more,
                                color: _pureWhite.withValues(alpha: 0.3),
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Expandable activity detail
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? _buildActivityDetail()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _deepCharcoal.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: _ironGrey, height: 16),
          Text(
            'ACTIVITY',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.activities.map((a) {
            final type = a['type'] as String;
            final dateStr = a['date'] as String?;
            if (type == 'trade') {
              final from = _profileName(
                a['fromProfile'] as Map<String, dynamic>?,
              );
              final to = _profileName(a['toProfile'] as Map<String, dynamic>?);
              return _activityRow(
                Icons.swap_horiz,
                _neonGreen,
                'TRADE',
                '$from → $to',
                _fmtDate(dateStr),
              );
            } else if (type == 'lend') {
              final lender = _profileName(
                a['lenderProfile'] as Map<String, dynamic>?,
              );
              final borrower = _profileName(
                a['borrowerProfile'] as Map<String, dynamic>?,
              );
              final status = a['status'] as String? ?? 'active';
              return _activityRow(
                Icons.handshake_outlined,
                const Color(0xFF00BCD4),
                status == 'active' ? 'LEND · ACTIVE' : 'LEND · RETURNED',
                '$lender → $borrower',
                _fmtDate(dateStr),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _activityRow(
    IconData icon,
    Color color,
    String label,
    String detail,
    String date,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.25),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialCircle(String letter) {
    return Container(
      width: 36,
      height: 36,
      color: _deepCharcoal,
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: _neonGreen,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// VIDEO LIGHTBOX — thumbnail + play button, taps open YouTube
// ═══════════════════════════════════════════════════════════════════

class _VideoLightbox extends StatelessWidget {
  final String videoUrl;
  final String label;
  final String? thumbnailUrl;

  const _VideoLightbox({
    required this.videoUrl,
    required this.label,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail background
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF121212)),
              )
            else
              Container(color: const Color(0xFF121212)),

            // Dark overlay
            Container(color: Colors.black.withValues(alpha: 0.6)),

            // Play button — taps open YouTube in browser tab
            Center(
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(videoUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF39FF14),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF39FF14,
                            ).withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                      ),
                      child: const Text(
                        'TAP TO WATCH ON YOUTUBE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Label + close
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2C2C2C).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GAMEPLAY LIGHTBOX
// ═══════════════════════════════════════════════════════════════════

class _GameplayLightbox extends StatefulWidget {
  final List<GameplayMedia> media;
  final int initialIndex;
  final Animation<double> animation;

  const _GameplayLightbox({
    required this.media,
    required this.initialIndex,
    required this.animation,
  });

  @override
  State<_GameplayLightbox> createState() => _GameplayLightboxState();
}

class _GameplayLightboxState extends State<_GameplayLightbox> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: media.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final item = media[index];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 3.0,
                      child: OgaImage(
                        path: item.imageUrl,
                        fit: BoxFit.contain,
                        accentColor: _neonGreen,
                        fallbackIcon: Icons.image,
                        fallbackIconSize: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _deepCharcoal.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _ironGrey.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: _pureWhite,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _deepCharcoal.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _ironGrey.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} OF ${media.length}',
                      style: const TextStyle(
                        color: _pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _deepCharcoal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ironGrey.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media[_currentIndex].gameName.toUpperCase(),
                      style: const TextStyle(
                        color: _neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      media[_currentIndex].caption,
                      style: TextStyle(
                        color: _pureWhite.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (media.length > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(media.length, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _neonGreen
                                  : _ironGrey.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
