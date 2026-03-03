// ═══════════════════════════════════════════════════════════════════
// GET CHARACTER MODAL — Sprint 13 v2
// Shows options to acquire a character from a friend:
//   1. Request Trade — opens TradeProposalModal (pick your character to offer)
//   2. Request Lend — opens LendRequestModal (ask owner to lend)
//   3. Buy (coming later)
//
// v2 FIX: "Request Lend" now correctly opens a BORROW request flow
// (ask the owner to lend YOU their character) instead of opening
// the LENDER flow (lend YOUR character to them).
//
// Opens from "GET THIS CHARACTER" button on locked characters
// when viewing a friend's library.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'trade_proposal_modal.dart';
import 'lend_request_modal.dart';

const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class GetCharacterModal {
  /// Shows the "Get This Character" bottom sheet with acquisition options.
  ///
  /// [characterId] — the character the user wants to acquire
  /// [ownerEmail] — the email of the friend who owns this character
  /// [ownerName] — display name of the friend (for UI text)
  /// [characterName] — display name of the character (for UI text)
  /// [characterImageUrl] — optional image URL for character preview
  static void show(
    BuildContext context, {
    required String characterId,
    required String ownerEmail,
    required String ownerName,
    required String characterName,
    String? characterImageUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GetCharacterSheet(
        characterId: characterId,
        ownerEmail: ownerEmail,
        ownerName: ownerName,
        characterName: characterName,
        characterImageUrl: characterImageUrl,
      ),
    );
  }
}

class _GetCharacterSheet extends StatelessWidget {
  final String characterId;
  final String ownerEmail;
  final String ownerName;
  final String characterName;
  final String? characterImageUrl;

  const _GetCharacterSheet({
    required this.characterId,
    required this.ownerEmail,
    required this.ownerName,
    required this.characterName,
    this.characterImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
            'GET ${characterName.toUpperCase()}',
            style: const TextStyle(
              color: _pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to get this character from $ownerName.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // ── Option 1: Trade ─────────────────────────────────
          _buildOption(
            context,
            icon: Icons.swap_horiz,
            iconColor: _neonGreen,
            title: 'REQUEST TRADE',
            subtitle: 'Offer one of your characters in exchange',
            onTap: () {
              Navigator.pop(context); // Close this sheet
              TradeProposalModal.show(
                context,
                characterId: characterId,
                friendEmail: ownerEmail,
              );
            },
          ),
          const SizedBox(height: 10),

          // ── Option 2: Request Lend (FIXED in v2) ────────────
          // Previously called LendProposalModal (lend YOUR character),
          // now correctly calls LendRequestModal (ask THEM to lend THEIR character).
          _buildOption(
            context,
            icon: Icons.handshake_outlined,
            iconColor: _lendCyan,
            title: 'REQUEST LEND',
            subtitle: 'Ask $ownerName to lend you this character temporarily',
            onTap: () {
              Navigator.pop(context); // Close this sheet
              LendRequestModal.show(
                context,
                characterId: characterId,
                characterName: characterName,
                ownerEmail: ownerEmail,
                ownerName: ownerName,
                characterImageUrl: characterImageUrl,
              );
            },
          ),
          const SizedBox(height: 10),

          // ── Option 3: Buy (coming later) ────────────────────
          _buildOption(
            context,
            icon: Icons.shopping_cart_outlined,
            iconColor: _pureWhite.withValues(alpha: 0.25),
            title: 'BUY CHARACTER',
            subtitle: 'Marketplace coming soon',
            disabled: true,
            onTap: () {},
          ),

          const SizedBox(height: 16),

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

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: disabled
              ? _voidBlack.withValues(alpha: 0.3)
              : _voidBlack.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? _ironGrey.withValues(alpha: 0.2)
                : _ironGrey.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: disabled ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withValues(alpha: disabled ? 0.1 : 0.25),
                ),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: disabled
                          ? _pureWhite.withValues(alpha: 0.25)
                          : _pureWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _pureWhite.withValues(
                        alpha: disabled ? 0.15 : 0.4,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!disabled)
              Icon(
                Icons.chevron_right,
                color: _pureWhite.withValues(alpha: 0.3),
                size: 20,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _ironGrey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SOON',
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.2),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
