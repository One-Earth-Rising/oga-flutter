// ═══════════════════════════════════════════════════════════════════════
// LEND PROPOSAL MODAL — Sprint 12
// Bottom sheet: select friend → select your character → set duration → send.
// Call via: LendProposalModal.show(context)
// Or pre-fill: LendProposalModal.show(context, friendEmail: '...', characterId: '...')
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/lend_service.dart';
import '../services/ownership_service.dart';
import '../services/friend_service.dart';
import '../config/oga_storage.dart';
import '../widgets/oga_image.dart';

class LendProposalModal extends StatefulWidget {
  final String? prefillFriendEmail;
  final String? prefillCharacterId;

  const LendProposalModal({
    super.key,
    this.prefillFriendEmail,
    this.prefillCharacterId,
  });

  /// Show the lend proposal as a bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    String? friendEmail,
    String? characterId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LendProposalModal(
        prefillFriendEmail: friendEmail,
        prefillCharacterId: characterId,
      ),
    );
  }

  @override
  State<LendProposalModal> createState() => _LendProposalModalState();
}

class _LendProposalModalState extends State<LendProposalModal> {
  // ─── Heimdal palette ─────────────────────────────────
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);
  static const Color lendCyan = Color(0xFF80DEEA);

  // ─── State ───────────────────────────────────────────
  int _step = 0; // 0=pick friend, 1=pick character, 2=set duration, 3=confirm
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  // Step 0: Friends
  List<FriendProfile> _friends = [];
  FriendProfile? _selectedFriend;

  // Step 1: My lendable characters
  List<OwnedCharacter> _myChars = [];
  OwnedCharacter? _selectedChar;

  // Step 2: Duration
  int _durationDays = 7;
  static const List<int> _durationOptions = [1, 3, 7, 14, 30];

  // Message
  final _messageController = TextEditingController();

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

  Future<void> _loadFriends() async {
    setState(() => _loading = true);
    try {
      final friends = await FriendService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _loading = false;
        });
        if (widget.prefillFriendEmail != null) {
          final matches = _friends.where(
            (f) => f.email == widget.prefillFriendEmail,
          );
          if (matches.isNotEmpty) _selectFriend(matches.first);
        }
      }
    } catch (e) {
      debugPrint('❌ Load friends error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectFriend(FriendProfile friend) async {
    setState(() {
      _selectedFriend = friend;
      _step = 1;
      _loading = true;
    });
    try {
      _myChars = await OwnershipService.getTradeableCharacters();
      if (mounted) {
        setState(() => _loading = false);
        if (widget.prefillCharacterId != null) {
          final matches = _myChars.where(
            (c) => c.characterId == widget.prefillCharacterId,
          );
          if (matches.isNotEmpty) _selectChar(matches.first);
        }
      }
    } catch (e) {
      debugPrint('❌ Load characters error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectChar(OwnedCharacter char) {
    setState(() {
      _selectedChar = char;
      _step = 2;
    });
  }

  Future<void> _submitLend() async {
    if (_selectedFriend == null || _selectedChar == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await LendService.proposeLend(
        borrowerEmail: _selectedFriend!.email,
        characterId: _selectedChar!.characterId,
        durationDays: _durationDays,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (mounted) {
        if (result == 'success') {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lend request sent for $_durationDays days!'),
              backgroundColor: lendCyan,
            ),
          );
        } else {
          setState(() {
            _error = result;
            _submitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: voidBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: ironGrey, width: 1),
          left: BorderSide(color: ironGrey, width: 1),
          right: BorderSide(color: ironGrey, width: 1),
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ironGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildHeader(),
          _buildStepIndicator(),
          const Divider(color: ironGrey, height: 1),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: lendCyan),
                  )
                : _buildStepContent(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'SELECT FRIEND',
      'YOUR CHARACTER',
      'SET DURATION',
      'CONFIRM LEND',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => setState(() {
                _step--;
                _error = null;
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          Text(
            titles[_step],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? lendCyan : ironGrey,
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
        return _buildFriendsList();
      case 1:
        return _buildCharacterPicker();
      case 2:
        return _buildDurationPicker();
      case 3:
        return _buildConfirmation();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 0: Friends list ─────────────────────────────

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No friends to lend to yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: deepCharcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ironGrey, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: ironGrey,
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? Text(
                      friend.name.isNotEmpty
                          ? friend.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              friend.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              friend.email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: lendCyan,
              size: 20,
            ),
            onTap: () => _selectFriend(friend),
          ),
        );
      },
    );
  }

  // ─── Step 1: Character picker ─────────────────────────

  Widget _buildCharacterPicker() {
    if (_myChars.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No characters available to lend',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _myChars.length,
      itemBuilder: (context, index) {
        final ownedChar = _myChars[index];
        final charName = ownedChar.character?.name ?? ownedChar.characterId;
        final charImagePath = ownedChar.character?.imagePath ?? '';

        return GestureDetector(
          onTap: () => _selectChar(ownedChar),
          child: Container(
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ironGrey, width: 1),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: charImagePath.isNotEmpty
                        ? OgaImage(
                            path: OgaStorage.resolve(charImagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            color: ironGrey,
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white24,
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    charName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Step 2: Duration picker ──────────────────────────

  Widget _buildDurationPicker() {
    final charName = _selectedChar?.character?.name ?? 'CHARACTER';
    final charImagePath = _selectedChar?.character?.imagePath ?? '';
    final friendName = _selectedFriend?.name ?? 'Friend';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected character preview
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lendCyan.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: charImagePath.isNotEmpty
                    ? OgaImage(
                        path: OgaStorage.resolve(charImagePath),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white24,
                          size: 40,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Lending ${charName.toUpperCase()} to $friendName',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          // Duration selector
          const Text(
            'LEND DURATION',
            style: TextStyle(
              color: lendCyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _durationOptions.map((days) {
              final isSelected = _durationDays == days;
              final label = days == 1 ? '1 DAY' : '$days DAYS';
              return GestureDetector(
                onTap: () => setState(() => _durationDays = days),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? lendCyan.withValues(alpha: 0.15)
                        : deepCharcoal,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? lendCyan : ironGrey,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? lendCyan : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lendCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: lendCyan.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: lendCyan.withValues(alpha: 0.6),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Character automatically returns to you after $_durationDays day${_durationDays == 1 ? '' : 's'}. You can also recall it early.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Optional message
          TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add a message (optional)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
                borderSide: const BorderSide(color: lendCyan),
              ),
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Next button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: lendCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'REVIEW LEND',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Confirmation ─────────────────────────────

  Widget _buildConfirmation() {
    final charName = _selectedChar?.character?.name ?? 'CHARACTER';
    final charImagePath = _selectedChar?.character?.imagePath ?? '';
    final friendName = _selectedFriend?.name ?? 'Friend';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Character card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: lendCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: lendCyan.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'LENDING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: lendCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: charImagePath.isNotEmpty
                      ? OgaImage(
                          path: OgaStorage.resolve(charImagePath),
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    charName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Details
          _buildDetailRow(Icons.person_outline, 'To', friendName),
          _buildDetailRow(
            Icons.schedule,
            'Duration',
            '$_durationDays day${_durationDays == 1 ? '' : 's'}',
          ),
          _buildDetailRow(Icons.keyboard_return, 'Returns', _returnDate()),
          if (_messageController.text.trim().isNotEmpty)
            _buildDetailRow(
              Icons.chat_bubble_outline,
              'Message',
              '"${_messageController.text.trim()}"',
            ),
          const SizedBox(height: 24),
          // Submit
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitLend,
              style: ElevatedButton.styleFrom(
                backgroundColor: lendCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: lendCyan.withValues(alpha: 0.3),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CONFIRM LEND',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ironGrey),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _returnDate() {
    final returnAt = DateTime.now().add(Duration(days: _durationDays));
    return '${returnAt.month}/${returnAt.day}/${returnAt.year}';
  }
}
