// ═══════════════════════════════════════════════════════════════════
// LEND REQUEST MODAL — Sprint 13
// Borrower-initiated flow: "I want to borrow YOUR character."
//
// This is DIFFERENT from LendProposalModal which is lender-initiated:
//   LendProposalModal: "I want to lend MY character to you"
//   LendRequestModal:  "I want to borrow YOUR character from you"
//
// Opens from "Request Lend" in GetCharacterModal when viewing a
// friend's locked character.
//
// Flow:
//   1. Shows the friend's character (already known)
//   2. User picks duration
//   3. User adds optional message
//   4. Creates a lend with status='requested'
//   5. Friend gets notification: "X wants to borrow your Guggimon"
//   6. Friend accepts → lend activates
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/lend_service.dart';
import '../models/oga_character.dart';

const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class LendRequestModal {
  /// Shows the lend request bottom sheet.
  ///
  /// [characterId] — the friend's character the user wants to borrow
  /// [characterName] — display name of the character
  /// [ownerEmail] — the friend who owns the character
  /// [ownerName] — display name of the friend
  /// [characterImageUrl] — optional image URL for the character preview
  static void show(
    BuildContext context, {
    required String characterId,
    required String characterName,
    required String ownerEmail,
    required String ownerName,
    String? characterImageUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LendRequestSheet(
        characterId: characterId,
        characterName: characterName,
        ownerEmail: ownerEmail,
        ownerName: ownerName,
        characterImageUrl: characterImageUrl,
      ),
    );
  }
}

class _LendRequestSheet extends StatefulWidget {
  final String characterId;
  final String characterName;
  final String ownerEmail;
  final String ownerName;
  final String? characterImageUrl;

  const _LendRequestSheet({
    required this.characterId,
    required this.characterName,
    required this.ownerEmail,
    required this.ownerName,
    this.characterImageUrl,
  });

  @override
  State<_LendRequestSheet> createState() => _LendRequestSheetState();
}

class _LendRequestSheetState extends State<_LendRequestSheet> {
  int _selectedDays = 7;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  static const _durations = [1, 3, 7, 14, 30];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: _ironGrey, width: 1),
          left: BorderSide(color: _ironGrey, width: 1),
          right: BorderSide(color: _ironGrey, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _ironGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'REQUEST ${widget.characterName.toUpperCase()}',
            style: const TextStyle(
              color: _pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask ${widget.ownerName} to lend you this character.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Character preview
          _buildCharacterPreview(),
          const SizedBox(height: 24),

          // Duration picker
          _buildDurationPicker(),
          const SizedBox(height: 8),

          // Duration info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _lendCyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _lendCyan.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _lendCyan, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Character returns to ${widget.ownerName} after $_selectedDays ${_selectedDays == 1 ? 'day' : 'days'}. They can also recall it early.',
                    style: TextStyle(
                      color: _lendCyan.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Message input
          TextField(
            controller: _messageController,
            maxLength: 200,
            maxLines: 2,
            style: const TextStyle(color: _pureWhite, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add a message (optional)',
              hintStyle: TextStyle(
                color: _pureWhite.withValues(alpha: 0.25),
                fontSize: 13,
              ),
              filled: true,
              fillColor: _voidBlack.withValues(alpha: 0.3),
              counterStyle: TextStyle(
                color: _pureWhite.withValues(alpha: 0.2),
                fontSize: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _ironGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _ironGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _lendCyan),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lendCyan,
                foregroundColor: _voidBlack,
                disabledBackgroundColor: _lendCyan.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _voidBlack,
                      ),
                    )
                  : const Text(
                      'SEND REQUEST',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.4),
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

  // ─── CHARACTER PREVIEW ───────────────────────────────────────

  Widget _buildCharacterPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Character image or placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _ironGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _lendCyan.withValues(alpha: 0.3)),
            ),
            child: widget.characterImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.characterImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderIcon(),
                    ),
                  )
                : _buildPlaceholderIcon(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.characterName.toUpperCase(),
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Owned by ${widget.ownerName}',
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Lend icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _lendCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.handshake_outlined, color: _lendCyan, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Text(
        widget.characterName.isNotEmpty
            ? widget.characterName[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: _lendCyan,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ─── DURATION PICKER ─────────────────────────────────────────

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEND DURATION',
          style: TextStyle(
            color: _pureWhite,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _durations.map((days) {
            final isSelected = _selectedDays == days;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: days == _durations.last ? 0 : 6,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDays = days),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _lendCyan.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _lendCyan
                            : _ironGrey.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$days ${days == 1 ? 'DAY' : 'DAYS'}',
                        style: TextStyle(
                          color: isSelected
                              ? _lendCyan
                              : _pureWhite.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── SUBMIT ──────────────────────────────────────────────────

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final result = await LendService.requestLend(
      ownerEmail: widget.ownerEmail,
      characterId: widget.characterId,
      durationDays: _selectedDays,
      message: _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (result == 'success') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _deepCharcoal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _lendCyan.withValues(alpha: 0.3)),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: _lendCyan, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lend request sent to ${widget.ownerName}!',
                  style: const TextStyle(color: _pureWhite, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _error = result;
      });
    }
  }
}
