// ═══════════════════════════════════════════════════════════════════
// ACTIVITY SCREEN — Sprint 13
// Full notification feed with time-grouped items, inline actions
// for pending trades/lends/friend requests, and deep navigation.
//
// Entry: ⚡ icon in app bar → pushes this screen
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/trade_service.dart';
import '../services/lend_service.dart';
import '../services/friend_service.dart';

// ─── Brand Colors (Heimdal V2) ──────────────────────────────
const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<OGANotification> _notifications = [];
  bool _isLoading = true;
  String _activeFilter = 'all';
  StreamSubscription<OGANotification>? _realtimeSub;

  static const _filters = ['all', 'trade', 'lend', 'friend', 'system'];
  static const _filterLabels = {
    'all': 'ALL',
    'trade': 'TRADES',
    'lend': 'LENDS',
    'friend': 'FRIENDS',
    'system': 'SYSTEM',
  };

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Listen for new notifications in realtime
    _realtimeSub = NotificationService.onNewNotification.listen((n) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, n);
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final all = await NotificationService.getAll(limit: 100);
      if (mounted) {
        setState(() {
          _notifications = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ActivityScreen: load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OGANotification> get _filteredNotifications {
    if (_activeFilter == 'all') return _notifications;
    return _notifications.where((n) => n.category == _activeFilter).toList();
  }

  // ─── Time Grouping ────────────────────────────────────────

  Map<String, List<OGANotification>> get _groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<OGANotification>>{};

    for (final n in _filteredNotifications) {
      final nDate = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      String label;
      if (nDate == today) {
        label = 'Today';
      } else if (nDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = 'Older';
      }
      groups.putIfAbsent(label, () => []).add(n);
    }

    return groups;
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: _voidBlack,
      appBar: AppBar(
        backgroundColor: _voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ACTIVITY',
          style: TextStyle(
            color: _pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Mark all read
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'MARK ALL READ',
                style: TextStyle(
                  color: _neonGreen.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────
          _buildFilterBar(),
          const Divider(color: _ironGrey, height: 1),
          // ── Notification list ───────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _neonGreen),
                  )
                : _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: _neonGreen,
                    backgroundColor: _deepCharcoal,
                    onRefresh: _loadNotifications,
                    child: _buildNotificationList(isMobile),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ───────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.map((f) {
          final isActive = _activeFilter == f;
          final count = f == 'all'
              ? _notifications.length
              : _notifications.where((n) => n.category == f).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _neonGreen.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? _neonGreen.withValues(alpha: 0.4)
                          : _ironGrey.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _filterLabels[f] ?? f.toUpperCase(),
                        style: TextStyle(
                          color: isActive
                              ? _neonGreen
                              : _pureWhite.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _neonGreen.withValues(alpha: 0.2)
                                : _ironGrey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isActive
                                  ? _neonGreen
                                  : _pureWhite.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            color: _pureWhite.withValues(alpha: 0.15),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'all'
                ? 'NO ACTIVITY YET'
                : 'NO ${_filterLabels[_activeFilter]} ACTIVITY',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.3),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trade characters, lend to friends, or send\nfriend requests to see activity here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notification List ────────────────────────────────────

  Widget _buildNotificationList(bool isMobile) {
    final groups = _groupedNotifications;
    final orderedKeys = ['Today', 'Yesterday', 'Older'];

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 12,
      ),
      itemCount: orderedKeys.length,
      itemBuilder: (context, groupIndex) {
        final key = orderedKeys[groupIndex];
        final items = groups[key];
        if (items == null || items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                key,
                style: TextStyle(
                  color: _pureWhite.withValues(alpha: 0.35),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Items
            ...items.map((n) => _buildNotificationItem(n)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ─── Single Notification Item ─────────────────────────────

  Widget _buildNotificationItem(OGANotification notification) {
    final isUnread = !notification.isRead;
    final isActionable = _isActionable(notification);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? _neonGreen.withValues(alpha: 0.03) : _deepCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? _neonGreen.withValues(alpha: 0.15)
                : _ironGrey.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon ────────────────────────────────
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                // ── Content ─────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + unread dot
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
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
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Message
                      if (notification.message != null)
                        Text(
                          notification.message!,
                          style: TextStyle(
                            color: _pureWhite.withValues(alpha: 0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      // Timestamp
                      Text(
                        _timeAgo(notification.createdAt),
                        style: TextStyle(
                          color: _pureWhite.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Chevron ─────────────────────────────
                if (!isActionable)
                  Icon(
                    Icons.chevron_right,
                    color: _pureWhite.withValues(alpha: 0.15),
                    size: 18,
                  ),
              ],
            ),
            // ── Inline Action Buttons ─────────────────────
            if (isActionable) ...[
              const SizedBox(height: 12),
              _buildActionButtons(notification),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Notification Icon ────────────────────────────────────

  Widget _buildNotificationIcon(OGANotification notification) {
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ─── Inline Action Buttons ────────────────────────────────

  bool _isActionable(OGANotification n) {
    return n.type == 'trade_proposed' ||
        n.type == 'lend_proposed' ||
        n.type == 'friend_request';
  }

  Widget _buildActionButtons(OGANotification notification) {
    return Row(
      children: [
        // ACCEPT
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAccept(notification),
            style: ElevatedButton.styleFrom(
              backgroundColor: _neonGreen,
              foregroundColor: _voidBlack,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ACCEPT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // DECLINE
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleDecline(notification),
            style: OutlinedButton.styleFrom(
              foregroundColor: _pureWhite.withValues(alpha: 0.6),
              side: BorderSide(color: _ironGrey),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'DECLINE',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    setState(() {
      _notifications = _notifications
          .map(
            (n) => OGANotification(
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
            ),
          )
          .toList();
    });
    NotificationService.resetUnread();
  }

  Future<void> _handleNotificationTap(OGANotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
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

    // Deep link based on type
    if (!mounted) return;
    _navigateForNotification(notification);
  }

  void _navigateForNotification(OGANotification notification) {
    switch (notification.type) {
      case 'trade_proposed':
      case 'trade_accepted':
      case 'trade_declined':
      case 'trade_cancelled':
        // Navigate to the character involved in the trade
        _navigateToCharacter(
          notification.referenceId,
          notification.referenceType,
        );
        break;
      case 'lend_proposed':
      case 'lend_accepted':
      case 'lend_returned':
      case 'lend_recalled':
      case 'lend_expiring_soon':
      case 'lend_declined':
        _navigateToCharacter(
          notification.referenceId,
          notification.referenceType,
        );
        break;
      case 'friend_request':
      case 'friend_accepted':
        // Pop back to dashboard, switch to friends tab
        Navigator.of(context).pop({'switchToTab': 'FRIENDS'});
        break;
      default:
        // Generic: just close activity screen
        break;
    }
  }

  void _navigateToCharacter(String referenceId, String referenceType) {
    // For now, pop back — in a future sprint we can deep-link to the
    // specific character detail screen using the trade/lend reference
    Navigator.of(context).pop();
    // TODO: resolve character_id from trade/lend reference_id and navigate
    // Navigator.pushNamed(context, '/character/$characterId');
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
      // Mark as read and reload
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

  // ─── Helpers ──────────────────────────────────────────────

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _deepCharcoal,
        behavior: SnackBarBehavior.floating,
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
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: _pureWhite, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
