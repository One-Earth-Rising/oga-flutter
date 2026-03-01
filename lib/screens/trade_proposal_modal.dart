// ═══════════════════════════════════════════════════════════════════════
// TRADE PROPOSAL MODAL — Sprint 12
// 4-step bottom sheet: pick friend → pick their char → pick your char → confirm
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/trade_service.dart';
import '../services/ownership_service.dart';
import '../config/oga_storage.dart';
import '../widgets/oga_image.dart';

class TradeProposalModal extends StatefulWidget {
  final String? prefillFriendEmail;
  final String? prefillCharacterId;

  const TradeProposalModal({
    super.key,
    this.prefillFriendEmail,
    this.prefillCharacterId,
  });

  /// Show the trade proposal modal as a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    String? friendEmail,
    String? characterId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TradeProposalModal(
        prefillFriendEmail: friendEmail,
        prefillCharacterId: characterId,
      ),
    );
  }

  @override
  State<TradeProposalModal> createState() => _TradeProposalModalState();
}

class _TradeProposalModalState extends State<TradeProposalModal> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  int _step = 0; // 0=friend, 1=their char, 2=your char, 3=confirm
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // Selected values
  FriendProfile? _selectedFriend;
  OwnedCharacter? _selectedTheirChar;
  OwnedCharacter? _selectedYourChar;
  final _messageController = TextEditingController();

  // Data lists
  List<FriendProfile> _friends = [];
  List<OwnedCharacter> _theirCharacters = [];
  List<OwnedCharacter> _yourCharacters = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      _friends = await FriendService.getFriends();
      // If prefilled friend, auto-select and advance
      if (widget.prefillFriendEmail != null) {
        final match = _friends
            .where((f) => f.email == widget.prefillFriendEmail)
            .toList();
        if (match.isNotEmpty) {
          _selectedFriend = match.first;
          await _loadTheirCharacters();
          _step = 1;
        }
      }
    } catch (e) {
      debugPrint('❌ TradeProposalModal: error loading friends: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTheirCharacters() async {
    if (_selectedFriend == null) return;
    setState(() => _isLoading = true);
    try {
      _theirCharacters = await OwnershipService.getFriendCharacters(
        _selectedFriend!.email,
      );
      // If prefilled character, auto-select and advance
      if (widget.prefillCharacterId != null) {
        final match = _theirCharacters
            .where((c) => c.characterId == widget.prefillCharacterId)
            .toList();
        if (match.isNotEmpty) {
          _selectedTheirChar = match.first;
          await _loadYourCharacters();
          _step = 2;
        }
      }
    } catch (e) {
      debugPrint('❌ TradeProposalModal: error loading their characters: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadYourCharacters() async {
    setState(() => _isLoading = true);
    try {
      _yourCharacters = await OwnershipService.getTradeableCharacters();
    } catch (e) {
      debugPrint('❌ TradeProposalModal: error loading your characters: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitTrade() async {
    if (_selectedFriend == null ||
        _selectedTheirChar == null ||
        _selectedYourChar == null)
      return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final result = await TradeService.proposeTrade(
      receiverEmail: _selectedFriend!.email,
      offeredCharacterId: _selectedYourChar!.characterId,
      requestedCharacterId: _selectedTheirChar!.characterId,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );

    if (!mounted) return;

    if (result == 'success') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'TRADE PROPOSED!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _error = result;
        _isSubmitting = false;
      });
    }
  }

  // ─── Helpers ───────────────────────────────────────────

  String _charName(OwnedCharacter? oc) =>
      oc?.character?.name ?? oc?.characterId ?? '';
  String _charImagePath(OwnedCharacter? oc) => oc?.character?.imagePath ?? '';
  Color _charAccent(OwnedCharacter? oc) =>
      oc?.character?.accentColorOverride ?? neonGreen;

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: voidBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ironGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _step--),
                  ),
                const Icon(Icons.swap_horiz, color: neonGreen, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'PROPOSE TRADE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 8),
          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: neonGreen),
                  )
                : _buildStepContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? neonGreen : ironGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildFriendPicker();
      case 1:
        return _buildTheirCharPicker();
      case 2:
        return _buildYourCharPicker();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 0: Pick a friend ─────────────────────────────

  Widget _buildFriendPicker() {
    if (_friends.isEmpty) {
      return const Center(
        child: Text(
          'No friends yet.\nAdd friends to start trading!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];

        return GestureDetector(
          onTap: () async {
            _selectedFriend = friend;
            await _loadTheirCharacters();
            if (mounted) setState(() => _step = 1);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                _buildAvatar(friend.name, friend.avatarUrl),
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
                      Text(
                        friend.email,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white24,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Step 1: Pick their character ──────────────────────

  Widget _buildTheirCharPicker() {
    if (_theirCharacters.isEmpty) {
      return Center(
        child: Text(
          '${_selectedFriend?.name ?? "Friend"} has no tradeable characters.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'PICK A CHARACTER FROM ${(_selectedFriend?.name ?? "FRIEND").toUpperCase()}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _theirCharacters.length,
            itemBuilder: (context, index) {
              final ownedChar = _theirCharacters[index];
              return _buildCharacterCard(ownedChar, 'YOU GET', () async {
                _selectedTheirChar = ownedChar;
                await _loadYourCharacters();
                if (mounted) setState(() => _step = 2);
              });
            },
          ),
        ),
      ],
    );
  }

  // ─── Step 2: Pick your character ───────────────────────

  Widget _buildYourCharPicker() {
    if (_yourCharacters.isEmpty) {
      return const Center(
        child: Text(
          'You have no tradeable characters.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'PICK A CHARACTER TO OFFER',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _yourCharacters.length,
            itemBuilder: (context, index) {
              final ownedChar = _yourCharacters[index];
              return _buildCharacterCard(ownedChar, 'YOU GIVE', () {
                setState(() {
                  _selectedYourChar = ownedChar;
                  _step = 3;
                });
              });
            },
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Confirm ──────────────────────────────────

  Widget _buildConfirmStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Trade visualization: YOUR CHAR ↔ THEIR CHAR
          Row(
            children: [
              Expanded(
                child: _buildConfirmCard(
                  _selectedYourChar,
                  'YOU GIVE',
                  const Color(0xFFFF5252),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, color: neonGreen, size: 28),
              ),
              Expanded(
                child: _buildConfirmCard(
                  _selectedTheirChar,
                  'YOU GET',
                  neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trading with
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Text(
                  'TRADING WITH  ',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                _buildAvatar(
                  _selectedFriend?.name ?? '',
                  _selectedFriend?.avatarUrl,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  (_selectedFriend?.name ?? '').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Message input
          TextField(
            controller: _messageController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add a message (optional)',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: deepCharcoal,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ironGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ironGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: neonGreen),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'SEND TRADE PROPOSAL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ────────────────────────────────────

  Widget _buildCharacterCard(
    OwnedCharacter ownedChar,
    String label,
    VoidCallback onTap,
  ) {
    final imagePath = _charImagePath(ownedChar);
    final accentColor = _charAccent(ownedChar);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: imagePath.isNotEmpty
                    ? OgaImage(
                        path: OgaStorage.resolve(imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        width: double.infinity,
                        color: accentColor.withValues(alpha: 0.08),
                        child: Center(
                          child: Text(
                            _charName(ownedChar).substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    _charName(ownedChar).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: label == 'YOU GIVE'
                          ? const Color(0xFFFF5252)
                          : neonGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
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

  Widget _buildConfirmCard(
    OwnedCharacter? ownedChar,
    String label,
    Color labelColor,
  ) {
    final imagePath = _charImagePath(ownedChar);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: labelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imagePath.isNotEmpty
                  ? OgaImage(
                      path: OgaStorage.resolve(imagePath),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: labelColor.withValues(alpha: 0.08),
                      child: Center(
                        child: Text(
                          _charName(ownedChar).isNotEmpty
                              ? _charName(
                                  ownedChar,
                                ).substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _charName(ownedChar).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl, {double size = 36}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(name, size),
        ),
      );
    }
    return _buildAvatarFallback(name, size);
  }

  Widget _buildAvatarFallback(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: neonGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: neonGreen,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
