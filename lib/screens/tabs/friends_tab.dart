import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/friend_service.dart';
import '../share_profile_screen.dart';
import '../friend_profile_screen.dart';

/// Friends tab with real Supabase data.
/// Features: "Invited by" card, friend list, invite code search, add friend, pending requests.
class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  final _searchController = TextEditingController();

  List<FriendProfile> _friends = [];
  List<FriendProfile> _pendingRequests = [];
  String? _myInviteCode;
  bool _isLoading = true;
  String _searchQuery = '';

  // Invited-by state
  String? _invitedByCode;
  InviterProfile? _invitedByProfile;

  // Invite code search state
  bool _isSearchingCode = false;
  FriendProfile? _foundUser;
  String? _searchError;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      FriendService.getFriends(),
      FriendService.getPendingRequests(),
      FriendService.getMyInviteCode(),
    ]);

    // Load invited_by info
    await _loadInvitedBy();

    setState(() {
      _friends = results[0] as List<FriendProfile>;
      _pendingRequests = results[1] as List<FriendProfile>;
      _myInviteCode = results[2] as String?;
      _isLoading = false;
    });
  }

  Future<void> _loadInvitedBy() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('invited_by')
          .eq('email', user.email!)
          .maybeSingle();

      final code = response?['invited_by'] as String?;
      if (code != null && code.isNotEmpty) {
        final profile = await FriendService.getPublicProfile(code);
        setState(() {
          _invitedByCode = code;
          _invitedByProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading invited_by: $e');
    }
  }

  List<FriendProfile> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends
        .where(
          (f) =>
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.email.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final horizontalPadding = isMobile ? 16.0 : 40.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: neonGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'FRIENDS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isLoading)
                    Text(
                      '${_friends.length}',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════
              // INVITED BY — permanent card (Clubhouse style)
              // ═══════════════════════════════════════════════════════
              if (_invitedByProfile != null) ...[
                _buildInvitedByCard(),
                const SizedBox(height: 16),
              ],

              // Your invite code card
              if (_myInviteCode != null) _buildMyInviteCode(),
              if (_myInviteCode != null) ...[
                const SizedBox(height: 10),
                _buildShareProfileButton(),
              ],
              const SizedBox(height: 16),

              // Add friend by code
              _buildAddByCode(),
              const SizedBox(height: 16),

              // Search existing friends
              if (_friends.isNotEmpty) ...[
                _buildSearchBar(),
                const SizedBox(height: 16),
              ],

              // Loading
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: neonGreen),
                  ),
                )
              else ...[
                // Pending requests
                if (_pendingRequests.isNotEmpty) ...[
                  _buildSubHeader('PENDING REQUESTS'),
                  const SizedBox(height: 10),
                  ..._pendingRequests.map((f) => _buildPendingRow(f)),
                  const SizedBox(height: 24),
                ],

                // Friends list
                if (_filteredFriends.isNotEmpty) ...[
                  _buildSubHeader('YOUR FRIENDS'),
                  const SizedBox(height: 10),
                  ..._filteredFriends.map((f) => _buildFriendRow(f)),
                ],

                // Empty state
                if (_friends.isEmpty && _pendingRequests.isEmpty)
                  _buildEmptyState(),
              ],

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INVITED BY CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildInvitedByCard() {
    final inviter = _invitedByProfile!;

    return GestureDetector(
      onTap: () {
        // Convert InviterProfile to FriendProfile for navigation
        final friendProfile = FriendProfile(
          email: '', // Not available from public profile
          name: inviter.displayName,
          avatarUrl: inviter.avatarUrl,
          starterCharacter: inviter.starterCharacter,
          inviteCode: inviter.inviteCode,
          createdAt: inviter.createdAt,
        );
        // Check if inviter is in friends list (has email)
        final matchedFriend = _friends.where(
          (f) => f.inviteCode == inviter.inviteCode,
        );
        if (matchedFriend.isNotEmpty) {
          _openFriendProfile(matchedFriend.first);
        } else {
          _openFriendProfile(friendProfile);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ironGrey),
        ),
        child: Row(
          children: [
            // Inviter avatar
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: inviter.characterColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: inviter.characterColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: inviter.avatarUrl != null
                    ? Image.network(
                        inviter.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildInviterFallbackAvatar(),
                      )
                    : _buildInviterFallbackAvatar(),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: neonGreen.withValues(alpha: 0.6),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'INVITED BY',
                        style: TextStyle(
                          color: neonGreen.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inviter.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (inviter.username.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      '@${inviter.username}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Code badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: neonGreen.withValues(alpha: 0.15)),
              ),
              child: Text(
                _invitedByCode!,
                style: TextStyle(
                  color: neonGreen.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviterFallbackAvatar() {
    return Container(
      width: 44,
      height: 44,
      color: deepCharcoal,
      child: const Icon(Icons.person, color: Colors.white38, size: 22),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // YOUR INVITE CODE
  // ═══════════════════════════════════════════════════════════

  Widget _buildMyInviteCode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neonGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: neonGreen.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR INVITE CODE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _myInviteCode!,
                  style: const TextStyle(
                    color: neonGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share this code with friends to connect',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _myInviteCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Invite code copied!'),
                  backgroundColor: neonGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy, color: neonGreen, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareProfileButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShareProfileScreen(inviteCode: _myInviteCode),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: neonGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, color: Colors.black, size: 16),
            SizedBox(width: 8),
            Text(
              'SHARE PROFILE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
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
  // ADD BY INVITE CODE
  // ═══════════════════════════════════════════════════════════

  Widget _buildAddByCode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ironGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADD FRIEND BY CODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: voidBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ironGrey),
                  ),
                  child: TextField(
                    onChanged: (_) => setState(() {
                      _foundUser = null;
                      _searchError = null;
                      _requestSent = false;
                    }),
                    onSubmitted: (_) => _searchByCode(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'OGA-XXXX',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    controller: _codeController,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSearchingCode ? null : _searchByCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: neonGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSearchingCode
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.black, size: 18),
                ),
              ),
            ],
          ),

          // Search result
          if (_foundUser != null && !_requestSent) ...[
            const SizedBox(height: 14),
            _buildFoundUserCard(_foundUser!),
          ],
          if (_requestSent) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: neonGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Friend request sent!',
                    style: TextStyle(color: neonGreen, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (_searchError != null) ...[
            const SizedBox(height: 14),
            Text(
              _searchError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  final _codeController = TextEditingController();

  Future<void> _searchByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isSearchingCode = true;
      _foundUser = null;
      _searchError = null;
      _requestSent = false;
    });

    final result = await FriendService.findByInviteCode(code);

    setState(() {
      _isSearchingCode = false;
      if (result != null) {
        final alreadyFriend = _friends.any((f) => f.email == result.email);
        if (alreadyFriend) {
          _searchError = 'You\'re already friends with ${result.name}!';
        } else {
          _foundUser = result;
        }
      } else {
        _searchError = 'No user found with code "$code"';
      }
    });
  }

  Widget _buildFoundUserCard(FriendProfile user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: voidBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ironGrey),
      ),
      child: Row(
        children: [
          _buildAvatar(user, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (user.starterCharacter != null)
                  Text(
                    user.starterCharacter!.toUpperCase(),
                    style: TextStyle(
                      color: user.characterColor.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final success = await FriendService.sendFriendRequest(user.email);
              if (success) {
                setState(() => _requestSent = true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: neonGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ADD',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ironGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white24, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FRIEND ROWS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSubHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildFriendRow(FriendProfile friend) {
    return GestureDetector(
      onTap: () => _openFriendProfile(friend),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            _buildAvatar(friend, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.email,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Character badge
            if (friend.starterCharacter != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: friend.characterColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: friend.characterColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  friend.starterCharacter!.toUpperCase(),
                  style: TextStyle(
                    color: friend.characterColor.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Chevron indicator
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
            // More menu
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz,
                color: Colors.white24,
                size: 18,
              ),
              color: deepCharcoal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: ironGrey.withValues(alpha: 0.5)),
              ),
              onSelected: (value) async {
                if (value == 'remove') {
                  final confirmed = await _confirmRemove(friend.name);
                  if (confirmed) {
                    await FriendService.removeFriend(friend.email);
                    _loadData();
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove Friend',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRow(FriendProfile friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: neonGreen.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _buildAvatar(friend, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wants to be your friend',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Accept
          GestureDetector(
            onTap: () async {
              await FriendService.acceptRequest(friend.email);
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: neonGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ACCEPT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Decline
          GestureDetector(
            onTap: () async {
              await FriendService.declineRequest(friend.email);
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: ironGrey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, color: Colors.white38, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AVATAR & HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _buildAvatar(FriendProfile friend, {double size = 40}) {
    if (friend.avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.network(
          friend.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLetterAvatar(friend, size),
        ),
      );
    }
    return _buildLetterAvatar(friend, size);
  }

  Widget _buildLetterAvatar(FriendProfile friend, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: friend.characterColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: friend.characterColor.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: friend.characterColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white.withValues(alpha: 0.15),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share your invite code to start connecting!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFriendProfile(FriendProfile friend) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend)),
    );
  }

  Future<bool> _confirmRemove(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: deepCharcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ironGrey),
            ),
            title: const Text(
              'Remove Friend',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Remove $name from your friends?',
              style: const TextStyle(color: Colors.white54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'REMOVE',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
