// ═══════════════════════════════════════════════════════════════════════
// ACTIVITY SCREEN — Sprint 13 (v2.1 — View All)
// Full-page notification list with category filter tabs.
//
// v2.1 FIXES:
//   1. Client-side category filtering (no dependency on
//      NotificationService.getAll having a 'category' param).
//   2. Same actionable gating as dropdown v3: buttons only show for
//      unread + actionable-type + not-yet-acted-on notifications.
//   3. Accept/decline handlers mark read + refresh list.
//   4. onActionCompleted callback for dashboard library refresh.
//   5. Category tabs: ALL | TRADES | LENDS | FRIENDS | SYSTEM
//   6. Sender initial avatar for actionable rows.
//   7. Cosmetic: __ → _ in separatorBuilder.
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => ActivityScreen(
//       onActionCompleted: () { _loadOwnership(); setState(() {}); },
//     ),
//   ));
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/trade_service.dart';
import '../services/lend_service.dart';
import '../services/friend_service.dart';
import '../widgets/notification_detail_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _voidBlack = Color(0xFF000000);
const Color _deepCharcoal = Color(0xFF121212);
const Color _neonGreen = Color(0xFF39FF14);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _lendCyan = Color(0xFF00BCD4);

class ActivityScreen extends StatefulWidget {
  final VoidCallback? onActionCompleted;

  const ActivityScreen({super.key, this.onActionCompleted});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<OGANotification> _allNotifications = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  final Set<String> _actedOnIds = {};
  final Map<String, Map<String, dynamic>> _avatarCache = {};

  static const _categories = [
    {'label': 'ALL', 'value': 'all'},
    {'label': 'TRADES', 'value': 'trade'},
    {'label': 'LENDS', 'value': 'lend'},
    {'label': 'REQUESTS', 'value': 'friend'},
    {'label': 'SYSTEM', 'value': 'system'},
  ];

  /// Client-side filter by selected category tab.
  List<OGANotification> get _filtered {
    if (_selectedCategory == 'all') return _allNotifications;
    return _allNotifications
        .where((n) => n.iconType == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final all = await NotificationService.getAll(limit: 50);
      debugPrint('>>> ACTIVITY: Loaded ${all.length} notifications');

      // Batch-fetch sender avatars
      final senderEmails = all
          .where((n) => n.senderEmail != null && n.senderEmail!.isNotEmpty)
          .map((n) => n.senderEmail!)
          .toSet()
          .where((e) => !_avatarCache.containsKey(e))
          .toList();

      if (senderEmails.isNotEmpty) {
        try {
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select('email, avatar_url, full_name')
              .inFilter('email', senderEmails);
          for (final p in profiles) {
            final email = p['email'] as String?;
            if (email != null) _avatarCache[email] = p;
          }
        } catch (e) {
          debugPrint('>>> ACTIVITY: avatar fetch error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _allNotifications = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('!!! ActivityScreen: load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isActionableType(String type) {
    return type == 'trade_proposed' ||
        type == 'lend_proposed' ||
        type == 'friend_request' ||
        type == 'lend_requested';
  }

  bool _shouldShowButtons(OGANotification n) {
    return !n.isRead &&
        _isActionableType(n.type) &&
        !_actedOnIds.contains(n.id);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filtered;
    return Scaffold(
      backgroundColor: _voidBlack,
      appBar: AppBar(
        backgroundColor: _deepCharcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ACTIVITY',
          style: TextStyle(
            color: _pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          if (_allNotifications.any((n) => !n.isRead))
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
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          const Divider(color: _ironGrey, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _neonGreen,
                      strokeWidth: 2,
                    ),
                  )
                : notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: _neonGreen,
                    backgroundColor: _deepCharcoal,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _i) => Divider(
                        color: _ironGrey.withValues(alpha: 0.3),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (_, i) =>
                          _buildNotificationRow(notifications[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY TABS ───────────────────────────────────────────

  Widget _buildCategoryTabs() {
    return Container(
      color: _deepCharcoal,
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = _selectedCategory == cat['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat['value']!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _neonGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? _neonGreen.withValues(alpha: 0.3)
                        : _ironGrey.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isActive
                        ? _neonGreen
                        : _pureWhite.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── NOTIFICATION ROW ────────────────────────────────────────

  Widget _buildNotificationRow(OGANotification notification) {
    final isUnread = !notification.isRead;
    final showButtons = _shouldShowButtons(notification);

    if (showButtons) {
      return Container(
        color: _neonGreen.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _openDetailSheet(notification),
              child: _buildInfoRow(notification, isUnread: true),
            ),
            const SizedBox(height: 10),
            _buildInlineActions(notification),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () => _handleTap(notification),
        child: Container(
          color: isUnread
              ? _neonGreen.withValues(alpha: 0.02)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildInfoRow(notification, isUnread: isUnread),
        ),
      );
    }
  }

  Widget _buildInfoRow(OGANotification notification, {required bool isUnread}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(notification),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        fontSize: 13,
                        fontWeight: isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: TextStyle(
                      color: _pureWhite.withValues(alpha: 0.2),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (notification.message != null) ...[
                const SizedBox(height: 4),
                Text(
                  notification.message!,
                  style: TextStyle(
                    color: _pureWhite.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!isUnread && _isActionableType(notification.type)) ...[
                const SizedBox(height: 4),
                _buildResolvedBadge(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResolvedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _ironGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'RESOLVED',
        style: TextStyle(
          color: _pureWhite.withValues(alpha: 0.3),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── ICON ────────────────────────────────────────────────────

  Widget _buildIcon(OGANotification notification) {
    IconData icon;
    Color color;
    switch (notification.iconType) {
      case 'trade':
        icon = Icons.swap_horiz;
        color = _neonGreen;
      case 'lend':
        icon = Icons.handshake_outlined;
        color = _lendCyan;
      case 'friend':
        icon = Icons.person_add_outlined;
        color = const Color(0xFF7C4DFF);
      case 'grant':
        icon = Icons.card_giftcard;
        color = const Color(0xFFFFD700);
      case 'system':
        icon = Icons.campaign_outlined;
        color = _pureWhite;
      default:
        icon = Icons.notifications_outlined;
        color = _pureWhite.withValues(alpha: 0.5);
    }

    if (notification.senderEmail != null &&
        notification.senderEmail!.isNotEmpty) {
      final profile = _avatarCache[notification.senderEmail];
      final avatarUrl = profile?['avatar_url'] as String?;
      final fullName = profile?['full_name'] as String? ?? '';
      final initial = fullName.isNotEmpty
          ? fullName[0].toUpperCase()
          : notification.senderEmail!.substring(0, 1).toUpperCase();

      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _err) => Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ─── ACCEPT / DECLINE BUTTONS ────────────────────────────────

  Widget _buildInlineActions(OGANotification notification) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => _handleAccept(notification),
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonGreen,
                foregroundColor: _voidBlack,
                padding: EdgeInsets.zero,
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
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: () => _handleDecline(notification),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pureWhite.withValues(alpha: 0.5),
                side: const BorderSide(color: _ironGrey),
                padding: EdgeInsets.zero,
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
        ),
      ],
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    final catLabel = _selectedCategory == 'all'
        ? ''
        : ' ${_categories.firstWhere((c) => c['value'] == _selectedCategory)['label']}';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: _pureWhite.withValues(alpha: 0.08), size: 48),
          const SizedBox(height: 12),
          Text(
            'NO$catLabel ACTIVITY YET',
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.2),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Activity will appear here as you\ntrade, lend, and connect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _pureWhite.withValues(alpha: 0.12),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Opens detail sheet WITHOUT marking read (buttons stay visible on return).
  void _openDetailSheet(OGANotification notification) {
    if (!mounted) return;
    NotificationDetailSheet.show(
      context,
      notification: notification,
      onAccept: () => _handleAccept(notification),
      onDecline: () => _handleDecline(notification),
    );
  }

  Future<void> _handleTap(OGANotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
      _updateLocalReadState(notification.id);
    }
    // Open detail sheet
    if (mounted) {
      NotificationDetailSheet.show(
        context,
        notification: notification,
        onAccept: () => _handleAccept(notification),
        onDecline: () => _handleDecline(notification),
      );
    }
  }

  Future<void> _handleAccept(OGANotification notification) async {
    debugPrint(
      '>>> ACTIVITY ACCEPT: type=${notification.type} '
      'refId=${notification.referenceId}',
    );

    setState(() => _actedOnIds.add(notification.id));

    String result;
    String successMsg;

    switch (notification.type) {
      case 'trade_proposed':
        result = await TradeService.acceptTrade(notification.referenceId);
        successMsg = 'Trade completed! Your library has been updated.';
      case 'lend_proposed':
        result = await LendService.acceptLend(notification.referenceId);
        successMsg = 'Lend accepted! Character added to your library.';
      case 'lend_requested':
        result = await LendService.acceptLendRequest(notification.referenceId);
        successMsg = 'Lend request approved! Character sent to borrower.';
      case 'friend_request':
        final ok = await FriendService.acceptRequest(notification.referenceId);
        result = ok ? 'success' : 'Failed to accept friend request';
        successMsg = 'Friend request accepted!';
      default:
        return;
    }

    if (!mounted) return;

    if (result == 'success') {
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
      _updateLocalReadState(notification.id);
      await _loadNotifications();
      widget.onActionCompleted?.call();
      _showSnackBar(successMsg, isSuccess: true);
    } else {
      setState(() => _actedOnIds.remove(notification.id));
      _showSnackBar(result, isSuccess: false);
    }
  }

  Future<void> _handleDecline(OGANotification notification) async {
    debugPrint(
      '>>> ACTIVITY DECLINE: type=${notification.type} '
      'refId=${notification.referenceId}',
    );

    setState(() => _actedOnIds.add(notification.id));

    String result;
    String successMsg;

    switch (notification.type) {
      case 'trade_proposed':
        result = await TradeService.declineTrade(notification.referenceId);
        successMsg = 'Trade declined.';
      case 'lend_proposed':
        result = await LendService.declineLend(notification.referenceId);
        successMsg = 'Lend declined.';
      case 'lend_requested':
        result = await LendService.declineLendRequest(notification.referenceId);
        successMsg = 'Lend request declined.';
      case 'friend_request':
        final ok = await FriendService.declineRequest(notification.referenceId);
        result = ok ? 'success' : 'Failed to decline friend request';
        successMsg = 'Friend request declined.';
      default:
        return;
    }

    if (!mounted) return;

    if (result == 'success') {
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
      _updateLocalReadState(notification.id);
      await _loadNotifications();
      widget.onActionCompleted?.call();
      _showSnackBar(successMsg, isSuccess: true);
    } else {
      setState(() => _actedOnIds.remove(notification.id));
      _showSnackBar(result, isSuccess: false);
    }
  }

  void _updateLocalReadState(String notificationId) {
    if (!mounted) return;
    setState(() {
      final idx = _allNotifications.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        final n = _allNotifications[idx];
        _allNotifications[idx] = OGANotification(
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
        duration: const Duration(seconds: 3),
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
