// ═══════════════════════════════════════════════════════════════════
// NOTIFICATION DETAIL SHEET — Sprint 13
// Shows the full details of a trade/lend notification:
//   - What character is involved
//   - Who sent it
//   - Trade: what they're offering vs what they want
//   - Lend: what character, for how long
//   - Accept / Decline buttons (if actionable)
//
// Opens when tapping a notification ROW (not the accept/decline buttons)
// in either the dropdown or the View All screen.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../models/oga_character.dart';
import '../config/oga_storage.dart';

const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class NotificationDetailSheet {
  /// Shows the detail bottom sheet for a notification.
  /// Fetches the related trade/lend record and displays asset info.
  static void show(
    BuildContext context, {
    required OGANotification notification,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => _DetailSheet(
        notification: notification,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  final OGANotification notification;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _DetailSheet({
    required this.notification,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _details;
  Map<String, dynamic>? _senderProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final n = widget.notification;

      // Fetch sender profile (for avatar + name)
      if (n.senderEmail != null && n.senderEmail!.isNotEmpty) {
        final profile = await _supabase
            .from('profiles')
            .select('full_name, first_name, last_name, username, avatar_url')
            .eq('email', n.senderEmail!)
            .maybeSingle();
        _senderProfile = profile;
      }

      // Fetch the referenced trade or lend record
      if (n.referenceId.isNotEmpty) {
        if (n.referenceType == 'trade' || n.type.startsWith('trade_')) {
          final trade = await _supabase
              .from('trades')
              .select()
              .eq('id', n.referenceId)
              .maybeSingle();
          if (trade != null) {
            _details = {'type': 'trade', ...trade};
          }
        } else if (n.referenceType == 'lend' || n.type.startsWith('lend_')) {
          final lend = await _supabase
              .from('lends')
              .select()
              .eq('id', n.referenceId)
              .maybeSingle();
          if (lend != null) {
            _details = {'type': 'lend', ...lend};
          }
        } else if (n.type == 'friend_request' || n.type == 'friend_accepted') {
          // No extra details needed for friend notifications
          _details = {'type': 'friend'};
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('!!! NotificationDetail: load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _getSenderName() {
    if (_senderProfile == null) {
      return widget.notification.senderEmail?.split('@').first ?? 'Unknown';
    }
    final first = _senderProfile!['first_name'] ?? '';
    final last = _senderProfile!['last_name'] ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return _senderProfile!['full_name'] ??
        widget.notification.senderEmail?.split('@').first ??
        'Unknown';
  }

  String? _getSenderAvatar() => _senderProfile?['avatar_url'] as String?;

  bool get _isActionable {
    final type = widget.notification.type;
    return !widget.notification.isRead &&
        (type == 'trade_proposed' ||
            type == 'lend_proposed' ||
            type == 'lend_requested' ||
            type == 'friend_request');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            48,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
            widget.notification.title,
            style: const TextStyle(
              color: _pureWhite,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: _neonGreen,
                strokeWidth: 2,
              ),
            )
          else if (_error != null)
            _buildErrorState()
          else ...[
            // Sender info
            _buildSenderRow(),
            const SizedBox(height: 16),

            // Detail content based on type
            if (_details?['type'] == 'trade')
              _buildTradeDetails()
            else if (_details?['type'] == 'lend')
              _buildLendDetails()
            else if (_details?['type'] == 'friend')
              _buildFriendDetails()
            else
              _buildGenericDetails(),

            // Message
            if (widget.notification.message != null) ...[
              const SizedBox(height: 16),
              _buildMessageCard(),
            ],

            // Action buttons
            if (_isActionable) ...[
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ],

          const SizedBox(height: 16),

          // Timestamp
          Text(
            _formatTimestamp(widget.notification.createdAt),
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.2),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SENDER ROW ──────────────────────────────────────────────────

  Widget _buildSenderRow() {
    final avatarUrl = _getSenderAvatar();
    final name = _getSenderName();
    final username = _senderProfile?['username'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(avatarUrl, name, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (username != null && username.isNotEmpty)
                  Text(
                    '@$username',
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Type badge
          _buildTypeBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name, double size) {
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialAvatar(name, size),
        ),
      );
    }
    return _buildInitialAvatar(name, size);
  }

  Widget _buildInitialAvatar(String name, double size) {
    final color = _getTypeColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: color,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    final type = widget.notification.type;
    if (type.startsWith('trade')) return _neonGreen;
    if (type.startsWith('lend')) return _lendCyan;
    if (type.startsWith('friend')) return const Color(0xFF7C4DFF);
    return _pureWhite;
  }

  Widget _buildTypeBadge() {
    final color = _getTypeColor();
    String label;
    if (widget.notification.type.startsWith('trade')) {
      label = 'TRADE';
    } else if (widget.notification.type.startsWith('lend')) {
      label = 'LEND';
    } else if (widget.notification.type.startsWith('friend')) {
      label = 'FRIEND';
    } else {
      label = 'SYSTEM';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── TRADE DETAILS ───────────────────────────────────────────────

  Widget _buildTradeDetails() {
    final offeredCharId =
        _details?['offered_character_id'] ??
        _details?['sender_character_id'] ??
        '';
    final requestedCharId =
        _details?['requested_character_id'] ??
        _details?['receiver_character_id'] ??
        '';
    final status = _details?['status'] ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // What they're offering
          _buildCharacterRow(
            label: 'OFFERING',
            characterId: offeredCharId,
            color: _neonGreen,
          ),
          const SizedBox(height: 12),
          // Swap icon
          Icon(
            Icons.swap_vert,
            color: _neonGreen.withValues(alpha: 0.4),
            size: 20,
          ),
          const SizedBox(height: 12),
          // What they want
          _buildCharacterRow(
            label: 'WANTS',
            characterId: requestedCharId,
            color: _neonGreen,
          ),
          const SizedBox(height: 12),
          // Status
          _buildStatusRow(status, _neonGreen),
        ],
      ),
    );
  }

  // ─── LEND DETAILS ────────────────────────────────────────────────

  Widget _buildLendDetails() {
    final characterId = _details?['character_id'] ?? '';
    final durationHours = _details?['duration_hours'] as int? ?? 168;
    final durationDays = durationHours ~/ 24;
    final status = _details?['status'] ?? 'unknown';
    final returnDueStr = _details?['return_due_at'] as String?;

    String timeInfo;
    if (returnDueStr != null) {
      final returnDue = DateTime.tryParse(returnDueStr);
      if (returnDue != null) {
        final remaining = returnDue.difference(DateTime.now());
        if (remaining.isNegative) {
          timeInfo = 'Overdue';
        } else if (remaining.inDays > 0) {
          timeInfo =
              '${remaining.inDays}d ${remaining.inHours % 24}h remaining';
        } else {
          timeInfo = '${remaining.inHours}h remaining';
        }
      } else {
        timeInfo = '$durationDays day${durationDays == 1 ? '' : 's'}';
      }
    } else {
      timeInfo = '$durationDays day${durationDays == 1 ? '' : 's'} requested';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lendCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildCharacterRow(
            label: 'CHARACTER',
            characterId: characterId,
            color: _lendCyan,
          ),
          const SizedBox(height: 12),
          // Duration
          Row(
            children: [
              Icon(Icons.timer_outlined, color: _lendCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'DURATION',
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                timeInfo,
                style: TextStyle(
                  color: _lendCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow(status, _lendCyan),
        ],
      ),
    );
  }

  // ─── FRIEND DETAILS ──────────────────────────────────────────────

  Widget _buildFriendDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline, color: const Color(0xFF7C4DFF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.notification.type == 'friend_request'
                  ? '${_getSenderName()} wants to be your friend!'
                  : '${_getSenderName()} accepted your friend request!',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── GENERIC DETAILS ─────────────────────────────────────────────

  Widget _buildGenericDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _pureWhite.withValues(alpha: 0.3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.notification.message ?? 'No additional details.',
              style: TextStyle(
                color: _pureWhite.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ──────────────────────────────────────────────

  /// Resolves a character ID to its OGACharacter data (name + image).
  Widget _buildCharacterRow({
    required String label,
    required String characterId,
    required Color color,
  }) {
    final character = OGACharacter.fromId(characterId);
    final displayName = character.name.toUpperCase();
    final heroImg = character.heroImage;
    final thumbImg = character.thumbnailImage;
    // Prefer thumbnail, fall back to hero
    final imgPath = thumbImg.isNotEmpty ? thumbImg : heroImg;
    final ipName = character.ip != 'Unknown' ? character.ip : null;

    return Row(
      children: [
        // Character thumbnail or fallback initial
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: imgPath.isNotEmpty
                ? Image.network(
                    OgaStorage.resolve(imgPath),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0] : '?',
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0] : '?',
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
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
                label,
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                displayName,
                style: const TextStyle(
                  color: _pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (ipName != null && ipName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  ipName,
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String status, Color color) {
    final statusColors = {
      'pending': _neonGreen,
      'requested': _lendCyan,
      'active': _neonGreen,
      'accepted': _neonGreen,
      'declined': Colors.redAccent,
      'cancelled': _ironGrey,
      'returned': _pureWhite,
    };
    final c = statusColors[status] ?? _ironGrey;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            color: c,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _voidBlack.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ironGrey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MESSAGE',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.notification.message!,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onAccept?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getTypeColor(),
                foregroundColor: _voidBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ACCEPT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDecline?.call();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _pureWhite.withValues(alpha: 0.5),
                side: const BorderSide(color: _ironGrey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'DECLINE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Could not load details.',
        style: TextStyle(
          color: _pureWhite.withValues(alpha: 0.4),
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
