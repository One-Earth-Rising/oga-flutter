import 'package:flutter/material.dart';

/// Friends tab content for the dashboard.
/// Shows friend list with online status, character avatars, and search.
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
  String _searchQuery = '';

  // Hardcoded friends for MVP
  static const List<_FriendData> _friends = [
    _FriendData(
      name: 'NIGHT KNIGHT',
      handle: '@nknight',
      character: 'Vegeta',
      characterColor: Color(0xFF2563EB),
      isOnline: true,
      level: 12,
    ),
    _FriendData(
      name: 'BISKIT',
      handle: '@BISKIT',
      character: 'Ryu',
      characterColor: Color(0xFFDC2626),
      isOnline: true,
      level: 8,
    ),
    _FriendData(
      name: 'OVERLY-OVER',
      handle: '@O-O',
      character: 'Guggimon',
      characterColor: Color(0xFF7C3AED),
      isOnline: false,
      level: 15,
    ),
    _FriendData(
      name: 'RYUMAIN99',
      handle: '@ryumain',
      character: 'Ryu',
      characterColor: Color(0xFFDC2626),
      isOnline: false,
      level: 22,
    ),
    _FriendData(
      name: 'GUGGIFAN',
      handle: '@guggifan',
      character: 'Guggimon',
      characterColor: Color(0xFF7C3AED),
      isOnline: true,
      level: 5,
    ),
  ];

  List<_FriendData> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends
        .where(
          (f) =>
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.handle.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  int get _onlineCount => _friends.where((f) => f.isOnline).length;

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
                  Text(
                    '${_friends.length}',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: neonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_onlineCount ONLINE',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search bar
              Container(
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search friends...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Add friend button
              GestureDetector(
                onTap: () {
                  // TODO: Add friend flow
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: neonGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: neonGreen.withValues(alpha: 0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, color: neonGreen, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'ADD FRIEND',
                        style: TextStyle(
                          color: neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Online friends section
              if (_filteredFriends.any((f) => f.isOnline)) ...[
                _buildSubHeader('ONLINE'),
                const SizedBox(height: 10),
                ..._filteredFriends
                    .where((f) => f.isOnline)
                    .map((f) => _buildFriendRow(f)),
                const SizedBox(height: 24),
              ],

              // Offline friends section
              if (_filteredFriends.any((f) => !f.isOnline)) ...[
                _buildSubHeader('OFFLINE'),
                const SizedBox(height: 10),
                ..._filteredFriends
                    .where((f) => !f.isOnline)
                    .map((f) => _buildFriendRow(f)),
              ],

              // Empty state
              if (_filteredFriends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No friends yet. Start by adding someone!'
                          : 'No friends matching "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildFriendRow(_FriendData friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: friend.characterColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: friend.characterColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    friend.character[0],
                    style: TextStyle(
                      color: friend.characterColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (friend.isOnline)
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: neonGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: deepCharcoal, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Name + handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.handle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Character + level
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                friend.character.toUpperCase(),
                style: TextStyle(
                  color: friend.characterColor.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'LVL ${friend.level}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // More options
          const Icon(Icons.more_horiz, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}

class _FriendData {
  final String name;
  final String handle;
  final String character;
  final Color characterColor;
  final bool isOnline;
  final int level;

  const _FriendData({
    required this.name,
    required this.handle,
    required this.character,
    required this.characterColor,
    required this.isOnline,
    required this.level,
  });
}
