// ═══════════════════════════════════════════════════════════════════════
// FRIENDS WHO OWN THIS — Sprint 14
// Marketplace-style list showing friends who own the same character.
// Launched from "FIND FRIENDS WHO OWN THIS" on locked character detail.
//
// Layout mirrors the Figma Marketplace screen:
//   Header card (character image + name + count + description)
//   Filter tabs (ALL | BEST PROGRESS | NEWEST)
//   Table: # | OWNER | ACQUIRED | PROGRESS | ACTION (TRADE / LEND)
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oga_character.dart';
import '../config/oga_storage.dart';
import '../modals/trade_proposal_modal.dart';
import '../modals/lend_proposal_modal.dart';

const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class FriendsWhoOwnModal extends StatefulWidget {
  /// The character the user is looking at (locked, doesn't own).
  final OGACharacter character;

  const FriendsWhoOwnModal({super.key, required this.character});

  /// Show as a full-screen dialog.
  static Future<void> show(BuildContext context, OGACharacter character) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: _voidBlack.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, a, b) => FriendsWhoOwnModal(character: character),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<FriendsWhoOwnModal> createState() => _FriendsWhoOwnModalState();
}

class _FriendsWhoOwnModalState extends State<FriendsWhoOwnModal> {
  List<_FriendOwnerRow> _allOwners = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  OGACharacter get ch => widget.character;

  List<_FriendOwnerRow> get _filtered {
    switch (_selectedFilter) {
      case 'progress':
        final sorted = List<_FriendOwnerRow>.from(_allOwners);
        sorted.sort((a, b) => b.progress.compareTo(a.progress));
        return sorted;
      case 'newest':
        final sorted = List<_FriendOwnerRow>.from(_allOwners);
        sorted.sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
        return sorted;
      default:
        return _allOwners;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFriendsWhoOwn();
  }

  Future<void> _loadFriendsWhoOwn() async {
    final supabase = Supabase.instance.client;
    final userEmail = supabase.auth.currentUser?.email;
    if (userEmail == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Step 1: Get accepted friends
      final friendRows = await supabase
          .from('friendships')
          .select('requester_email, receiver_email')
          .or('requester_email.eq.$userEmail,receiver_email.eq.$userEmail')
          .eq('status', 'accepted');

      final friendEmails = <String>{};
      for (final row in friendRows) {
        final req = row['requester_email'] as String?;
        final rec = row['receiver_email'] as String?;
        if (req != null && req != userEmail) friendEmails.add(req);
        if (rec != null && rec != userEmail) friendEmails.add(rec);
      }

      if (friendEmails.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Step 2: Find friends who own this character from TWO sources:
      //   A) character_ownership table (trades, grants)
      //   B) profiles.starter_character (onboarding acquisition)
      final baseId = ch.id.toLowerCase();

      // Source A: character_ownership table
      final ownershipRows = await supabase
          .from('character_ownership')
          .select('owner_email, character_id, acquired_at')
          .inFilter('owner_email', friendEmails.toList())
          .ilike('character_id', '$baseId%');

      // Source B: profiles.starter_character (friends whose starter matches)
      final starterProfiles = await supabase
          .from('profiles')
          .select('email, starter_character, created_at')
          .inFilter('email', friendEmails.toList())
          .ilike('starter_character', '$baseId%');

      // Merge: build a unified list, deduplicating by email
      final ownerEmailsFromTable = ownershipRows
          .map((r) => r['owner_email'] as String)
          .toSet();
      // ── DEBUG: Remove after diagnosis ──
      debugPrint('🔍 FriendsWhoOwn DEBUG:');
      debugPrint('   userEmail: $userEmail');
      debugPrint('   baseId: $baseId');
      debugPrint('   friendEmails: $friendEmails');
      debugPrint('   ownership rows: ${ownershipRows.length}');
      for (final r in ownershipRows) {
        debugPrint(
          '     ownership: ${r['owner_email']} → ${r['character_id']}',
        );
      }
      debugPrint('   starter profiles: ${starterProfiles.length}');
      for (final s in starterProfiles) {
        debugPrint('     starter: ${s['email']} → ${s['starter_character']}');
      }

      // Add starter_character owners as synthetic ownership rows
      final allOwnershipRows = [...ownershipRows];
      for (final sp in starterProfiles) {
        final email = sp['email'] as String? ?? '';
        if (email.isNotEmpty && !ownerEmailsFromTable.contains(email)) {
          allOwnershipRows.add({
            'owner_email': email,
            'character_id': sp['starter_character'] as String? ?? baseId,
            'acquired_at': sp['created_at']?.toString() ?? '',
            'is_active': true,
          });
        }
      }

      // Step 3: Batch-fetch profiles for those friends
      final ownerEmails = allOwnershipRows
          .map((r) => r['owner_email'] as String)
          .toSet();
      final profileMap = <String, Map<String, dynamic>>{};

      if (ownerEmails.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select(
              'email, full_name, first_name, last_name, username, avatar_url',
            )
            .inFilter('email', ownerEmails.toList());
        for (final p in profiles) {
          final email = p['email'] as String?;
          if (email != null) profileMap[email] = p;
        }
      }

      // Step 4: Build display rows
      final rows = <_FriendOwnerRow>[];
      for (final ownership in allOwnershipRows) {
        final email = ownership['owner_email'] as String;
        final profile = profileMap[email];
        final acquiredStr = ownership['acquired_at']?.toString() ?? '';
        final acquiredAt =
            DateTime.tryParse(acquiredStr) ?? DateTime(2025, 1, 1);

        rows.add(
          _FriendOwnerRow(
            email: email,
            displayName: _profileName(profile),
            username: profile?['username'] as String?,
            avatarUrl: profile?['avatar_url'] as String?,
            characterId: ownership['character_id'] as String? ?? ch.id,
            acquiredAt: acquiredAt,
            progress: 0.0, // TODO: fetch from portal_pass if available
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allOwners = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ FriendsWhoOwn load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _profileName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Unknown';
    final first = profile['first_name'] as String? ?? '';
    final last = profile['last_name'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return profile['full_name'] as String? ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW > 800;
    final modalWidth = isDesktop ? 760.0 : screenW * 0.95;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: modalWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: _deepCharcoal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ironGrey, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isDesktop),
              _buildFilterTabs(),
              const Divider(color: _ironGrey, height: 1),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(
                    color: _neonGreen,
                    strokeWidth: 2,
                  ),
                )
              else if (_allOwners.isEmpty)
                _buildEmptyState()
              else
                _buildOwnersList(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────

  Widget _buildHeader(bool isDesktop) {
    final imageUrl = ch.heroImage;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character thumbnail
          Container(
            width: isDesktop ? 100 : 72,
            height: isDesktop ? 100 : 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _ironGrey),
              color: _deepCharcoal,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      OgaStorage.resolve(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.name.toUpperCase(),
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!_isLoading) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_allOwners.length} FRIEND${_allOwners.length == 1 ? '' : 'S'} OWN THIS',
                    style: TextStyle(
                      color: _neonGreen.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  ch.description.length > 120
                      ? '${ch.description.substring(0, 120)}…'
                      : ch.description,
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _ironGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: _pureWhite, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(
        Icons.person_outline,
        color: _pureWhite.withValues(alpha: 0.15),
        size: 32,
      ),
    );
  }

  // ─── FILTER TABS ─────────────────────────────────────────────

  Widget _buildFilterTabs() {
    const filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'BEST PROGRESS', 'value': 'progress'},
      {'label': 'NEWEST', 'value': 'newest'},
    ];

    return Container(
      color: _deepCharcoal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final isActive = _selectedFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _neonGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? _neonGreen.withValues(alpha: 0.4)
                        : _ironGrey.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    color: isActive
                        ? _neonGreen
                        : _pureWhite.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── TABLE HEADER ────────────────────────────────────────────

  Widget _buildTableHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDesktop ? 12 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _ironGrey.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _colHeaderStyle())),
          Expanded(flex: 3, child: Text('OWNER', style: _colHeaderStyle())),
          if (isDesktop)
            Expanded(
              flex: 2,
              child: Text('ACQUIRED', style: _colHeaderStyle()),
            ),
          SizedBox(
            width: isDesktop ? 80 : 50,
            child: Center(child: Text('PROGRESS', style: _colHeaderStyle())),
          ),
          SizedBox(
            width: isDesktop ? 160 : 110,
            child: Text('', style: _colHeaderStyle()), // action column
          ),
        ],
      ),
    );
  }

  TextStyle _colHeaderStyle() {
    return TextStyle(
      color: _pureWhite.withValues(alpha: 0.25),
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );
  }

  // ─── OWNERS LIST ─────────────────────────────────────────────

  Widget _buildOwnersList(bool isDesktop) {
    final owners = _filtered;
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(isDesktop),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              shrinkWrap: true,
              itemCount: owners.length,
              separatorBuilder: (_, i) => Divider(
                color: _ironGrey.withValues(alpha: 0.15),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (_, i) =>
                  _buildOwnerRow(owners[i], i + 1, isDesktop),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerRow(_FriendOwnerRow owner, int rank, bool isDesktop) {
    final initial = owner.displayName.isNotEmpty
        ? owner.displayName[0].toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDesktop ? 14 : 12,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.3),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Avatar + Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
                    color: _voidBlack,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child:
                        owner.avatarUrl != null && owner.avatarUrl!.isNotEmpty
                        ? Image.network(
                            owner.avatarUrl!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, st) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: _neonGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: _neonGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owner.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: _pureWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (owner.username != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          '@${owner.username}',
                          style: TextStyle(
                            color: _pureWhite.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Acquired date (desktop only)
          if (isDesktop)
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(owner.acquiredAt),
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Progress ring
          SizedBox(
            width: isDesktop ? 80 : 50,
            child: Center(child: _buildProgressRing(owner.progress)),
          ),

          // Action buttons
          SizedBox(
            width: isDesktop ? 160 : 110,
            child: _buildActionButtons(owner, isDesktop),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS RING ───────────────────────────────────────────

  Widget _buildProgressRing(double progress) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: _ironGrey.withValues(alpha: 0.3),
              color: _neonGreen,
              strokeWidth: 3,
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              color: progress > 0
                  ? _neonGreen
                  : _pureWhite.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────────────

  Widget _buildActionButtons(_FriendOwnerRow owner, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // TRADE button
        SizedBox(
          height: 30,
          child: ElevatedButton(
            onPressed: () => _onTrade(owner),
            style: ElevatedButton.styleFrom(
              backgroundColor: _neonGreen,
              foregroundColor: _voidBlack,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: Text(
              'TRADE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: isDesktop ? 11 : 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // LEND button
        SizedBox(
          height: 30,
          child: OutlinedButton(
            onPressed: () => _onLend(owner),
            style: OutlinedButton.styleFrom(
              foregroundColor: _lendCyan,
              side: BorderSide(color: _lendCyan.withValues(alpha: 0.4)),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'LEND',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: isDesktop ? 11 : 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: _pureWhite.withValues(alpha: 0.08),
            size: 48,
          ),
          const SizedBox(height: 14),
          const Text(
            'NO FRIENDS OWN THIS CHARACTER',
            style: TextStyle(
              color: _pureWhite,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite more friends to grow your network\nand unlock trading opportunities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.35),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.share, size: 14),
              label: const Text(
                'INVITE FRIENDS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 11,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _neonGreen,
                side: BorderSide(color: _neonGreen.withValues(alpha: 0.4)),
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

  // ─── ACTIONS ─────────────────────────────────────────────────

  void _onTrade(_FriendOwnerRow owner) {
    Navigator.of(context).pop();
    // TODO: Enhance modal to pre-select counterparty (owner.email)
    TradeProposalModal.show(context, characterId: owner.characterId);
  }

  void _onLend(_FriendOwnerRow owner) {
    Navigator.of(context).pop();
    // TODO: Enhance modal to pre-select counterparty (owner.email)
    LendProposalModal.show(context, characterId: owner.characterId);
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── DATA MODEL ──────────────────────────────────────────────────

class _FriendOwnerRow {
  final String email;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String characterId;
  final DateTime acquiredAt;
  final double progress; // 0.0 - 1.0

  const _FriendOwnerRow({
    required this.email,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.characterId,
    required this.acquiredAt,
    this.progress = 0.0,
  });
}
