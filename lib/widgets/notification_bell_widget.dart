// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION BELL WIDGET — Sprint 13 (v2 — Dropdown)
// ⚡ icon with dropdown panel matching Figma Score menu aesthetic.
// Self-contained: listens to NotificationService streams.
//
// Usage:
//   NotificationBellWidget(
//     onViewAll: () => Navigator.push(...ActivityScreen),
//   )
// ═══════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/trade_service.dart';
import '../services/lend_service.dart';
import '../services/friend_service.dart';

// ─── Brand Colors (Heimdal V2) ──────────────────────────────────────
const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class NotificationBellWidget extends StatefulWidget {
  /// Called when user taps "VIEW ALL" — typically pushes full ActivityScreen
  final VoidCallback? onViewAll;

  /// Called when a friend-related action completes and caller should
  /// switch to the FRIENDS tab (passes {'switchToTab': 'FRIENDS'})
  final void Function(Map<String, dynamic>)? onDeepLink;

  const NotificationBellWidget({super.key, this.onViewAll, this.onDeepLink});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget>
    with SingleTickerProviderStateMixin {
  int _unreadCount = 0;
  StreamSubscription<int>? _countSub;
  StreamSubscription<OGANotification>? _newSub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Dropdown state
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    _unreadCount = NotificationService.unreadCount;

    _countSub = NotificationService.unreadCountStream.listen((count) {
      if (mounted) setState(() => _unreadCount = count);
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _newSub = NotificationService.onNewNotification.listen((_) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _countSub?.cancel();
    _newSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Scrim — tap anywhere to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown panel
          Positioned(
            width: 360,
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: _NotificationDropdownPanel(
                  onClose: _removeOverlay,
                  onViewAll: () {
                    _removeOverlay();
                    widget.onViewAll?.call();
                  },
                  onDeepLink: (data) {
                    _removeOverlay();
                    widget.onDeepLink?.call(data);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _isOpen
                  ? _neonGreen.withValues(alpha: 0.12)
                  : hasUnread
                  ? _neonGreen.withValues(alpha: 0.08)
                  : _deepCharcoal.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isOpen
                    ? _neonGreen.withValues(alpha: 0.4)
                    : hasUnread
                    ? _neonGreen.withValues(alpha: 0.25)
                    : _ironGrey.withValues(alpha: 0.5),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.bolt,
                  color: _isOpen || hasUnread
                      ? _neonGreen
                      : _pureWhite.withValues(alpha: 0.5),
                  size: 18,
                ),
                if (hasUnread)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _neonGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: _deepCharcoal, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _neonGreen.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DROPDOWN PANEL — The floating card (matches Figma Score dropdown)
// ═══════════════════════════════════════════════════════════════════════

class _NotificationDropdownPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onViewAll;
  final void Function(Map<String, dynamic>)? onDeepLink;

  const _NotificationDropdownPanel({
    required this.onClose,
    this.onViewAll,
    this.onDeepLink,
  });

  @override
  State<_NotificationDropdownPanel> createState() =>
      _NotificationDropdownPanelState();
}

class _NotificationDropdownPanelState
    extends State<_NotificationDropdownPanel> {
  List<OGANotification> _notifications = [];
  bool _isLoading = true;

  static const int _maxVisible = 5;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final all = await NotificationService.getAll(limit: 20);
      if (mounted) {
        setState(() {
          _notifications = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ NotificationDropdown: load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      constraints: const BoxConstraints(maxHeight: 460),
      decoration: BoxDecoration(
        color: _deepCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ironGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: _voidBlack.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(color: _neonGreen.withValues(alpha: 0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────
          _buildHeader(unreadCount),
          const Divider(color: _ironGrey, height: 1),

          // ── Content ────────────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: _neonGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_notifications.isEmpty)
            _buildEmptyState()
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _notifications.length > _maxVisible
                    ? _maxVisible
                    : _notifications.length,
                separatorBuilder: (_, __) => Divider(
                  color: _ironGrey.withValues(alpha: 0.4),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) =>
                    _buildNotificationRow(_notifications[index]),
              ),
            ),

          // ── Footer ─────────────────────────────────────────────
          if (!_isLoading && _notifications.isNotEmpty) ...[
            const Divider(color: _ironGrey, height: 1),
            _buildFooter(),
          ],
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        children: [
          // Title
          const Text(
            'ACTIVITY',
            style: TextStyle(
              color: _pureWhite,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(width: 8),

          // ⚡ icon + unread count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _neonGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: _neonGreen, size: 12),
                const SizedBox(width: 3),
                Text(
                  '$unreadCount NEW',
                  style: const TextStyle(
                    color: _neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Mark all read
          if (unreadCount > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: Text(
                'MARK READ',
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Notification Row ───────────────────────────────────────────────

  Widget _buildNotificationRow(OGANotification notification) {
    final isUnread = !notification.isRead;
    final isActionable =
        notification.type == 'trade_proposed' ||
        notification.type == 'lend_proposed' ||
        notification.type == 'friend_request';

    return InkWell(
      onTap: () => _handleTap(notification),
      child: Container(
        color: isUnread
            ? _neonGreen.withValues(alpha: 0.03)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                _buildIcon(notification),
                const SizedBox(width: 10),

                // Title + message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                color: _neonGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: _pureWhite,
                                fontSize: 12,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (notification.message != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          notification.message!,
                          style: TextStyle(
                            color: _pureWhite.withValues(alpha: 0.45),
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Time
                Text(
                  _timeAgo(notification.createdAt),
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            // Inline action buttons for pending items
            if (isActionable) ...[
              const SizedBox(height: 8),
              _buildInlineActions(notification),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Notification Icon ──────────────────────────────────────────────

  Widget _buildIcon(OGANotification notification) {
    IconData icon;
    Color color;

    switch (notification.iconType) {
      case 'trade':
        icon = Icons.swap_horiz;
        color = _neonGreen;
        break;
      case 'lend':
        icon = Icons.handshake_outlined;
        color = _lendCyan;
        break;
      case 'friend':
        icon = Icons.person_add_outlined;
        color = const Color(0xFF7C4DFF);
        break;
      case 'grant':
        icon = Icons.card_giftcard;
        color = const Color(0xFFFFD700);
        break;
      case 'system':
        icon = Icons.campaign_outlined;
        color = _pureWhite;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = _pureWhite.withValues(alpha: 0.5);
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  // ─── Inline Accept/Decline ──────────────────────────────────────────

  Widget _buildInlineActions(OGANotification notification) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: () => _handleAccept(notification),
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonGreen,
                foregroundColor: _voidBlack,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ACCEPT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 28,
            child: OutlinedButton(
              onPressed: () => _handleDecline(notification),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pureWhite.withValues(alpha: 0.5),
                side: BorderSide(color: _ironGrey),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'DECLINE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: _pureWhite.withValues(alpha: 0.1), size: 36),
          const SizedBox(height: 10),
          Text(
            'NO ACTIVITY YET',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.25),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trades, lends, and friend requests\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.15),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return GestureDetector(
      onTap: widget.onViewAll,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'VIEW ALL',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _handleTap(OGANotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notification.id);
          if (idx >= 0) {
            final n = _notifications[idx];
            _notifications[idx] = OGANotification(
              id: n.id,
              recipientEmail: n.recipientEmail,
              type: n.type,
              referenceId: n.referenceId,
              referenceType: n.referenceType,
              message: n.message,
              isRead: true,
              createdAt: n.createdAt,
              senderEmail: n.senderEmail,
              thumbnailUrl: n.thumbnailUrl,
              actionUrl: n.actionUrl,
              category: n.category,
              priority: n.priority,
            );
          }
        });
      }
    }

    // Deep link for friend-related taps
    if (notification.type == 'friend_request' ||
        notification.type == 'friend_accepted') {
      widget.onDeepLink?.call({'switchToTab': 'FRIENDS'});
    }
  }

  Future<void> _handleAccept(OGANotification notification) async {
    String result;

    switch (notification.type) {
      case 'trade_proposed':
        result = await TradeService.acceptTrade(notification.referenceId);
        break;
      case 'lend_proposed':
        result = await LendService.acceptLend(notification.referenceId);
        break;
      case 'friend_request':
        final ok = await FriendService.acceptRequest(notification.referenceId);
        result = ok ? 'success' : 'Failed to accept friend request';
        break;
      default:
        return;
    }

    if (!mounted) return;

    if (result == 'success') {
      await NotificationService.markRead(notification.id);
      await _loadNotifications();
      _showSnackBar('Action completed!', isSuccess: true);
    } else {
      _showSnackBar(result, isSuccess: false);
    }
  }

  Future<void> _handleDecline(OGANotification notification) async {
    String result;

    switch (notification.type) {
      case 'trade_proposed':
        result = await TradeService.declineTrade(notification.referenceId);
        break;
      case 'lend_proposed':
        result = await LendService.declineLend(notification.referenceId);
        break;
      case 'friend_request':
        final ok = await FriendService.declineRequest(notification.referenceId);
        result = ok ? 'success' : 'Failed to decline friend request';
        break;
      default:
        return;
    }

    if (!mounted) return;

    if (result == 'success') {
      await NotificationService.markRead(notification.id);
      await _loadNotifications();
      _showSnackBar('Declined.', isSuccess: true);
    } else {
      _showSnackBar(result, isSuccess: false);
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    NotificationService.resetUnread();
    await _loadNotifications();
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _deepCharcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSuccess
                ? _neonGreen.withValues(alpha: 0.3)
                : Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? _neonGreen : Colors.redAccent,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: _pureWhite, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.month}/${dateTime.day}';
  }
}
