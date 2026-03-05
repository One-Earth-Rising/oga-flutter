// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION BELL WIDGET — Sprint 13 (v3.0 — Dropdown Fix)
// ⚡ icon with dropdown panel matching Figma Score menu aesthetic.
//
// v3.0 FIXES:
//   1. ACCEPT/DECLINE buttons now reliably visible for actionable
//      notifications in dropdown. Root cause: HitTestBehavior.opaque
//      on GestureDetector was swallowing taps. Now uses separate
//      widget branches for actionable vs informational rows.
//   2. Acted-on notifications flip to read immediately — buttons vanish.
//   3. onActionCompleted callback fires after successful accept/decline,
//      triggering dashboard library refresh.
//   4. Bell green dot no longer clipped on web (Clip.none on Stack).
//   5. Debug prints at showButtons evaluation for tracing.
//   6. Sender avatar placeholder (uses first letter of senderEmail).
//
// Usage:
//   NotificationBellWidget(
//     onViewAll: () => Navigator.push(...ActivityScreen),
//     onActionCompleted: () { _loadOwnership(); setState(() {}); },
//   )
// ═══════════════════════════════════════════════════════════════════════

import 'dart:async';
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

// ═══════════════════════════════════════════════════════════════════════
// BELL ICON (top bar)
// ═══════════════════════════════════════════════════════════════════════

class NotificationBellWidget extends StatefulWidget {
  final VoidCallback? onViewAll;
  final void Function(Map<String, dynamic>)? onDeepLink;
  final VoidCallback? onActionCompleted;

  const NotificationBellWidget({
    super.key,
    this.onViewAll,
    this.onDeepLink,
    this.onActionCompleted,
  });

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
    _countSub?.cancel();
    _newSub?.cancel();
    _pulseController.dispose();
    _removeOverlay();
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
          // Scrim: tapping outside closes dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown panel
          Positioned(
            width: 360,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-308, 48),
              child: Material(
                color: Colors.transparent,
                child: _NotificationDropdownPanel(
                  onClose: _removeOverlay,
                  onViewAll: () {
                    _removeOverlay();
                    if (widget.onViewAll != null) {
                      widget.onViewAll!();
                    } else {
                      Navigator.of(context).pushNamed('/activity');
                    }
                  },
                  onDeepLink: widget.onDeepLink,
                  onActionCompleted: widget.onActionCompleted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    // 1. We move the spacing OUTSIDE everything using Padding
    return Padding(
      padding: const EdgeInsets.only(
        right: 12.0,
      ), // Spacing between bell and avatar
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            // 2. Provide a fixed safe-zone (44x44) so the scale animation has room to breathe
            child: SizedBox(
              width: 44,
              height: 44,
              // 3. Center prevents the parent Row from stretching the child vertically
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    // 4. Strict, equal dimensions guarantee a perfect circle
                    width: 34,
                    height: 34,
                    // NO MARGIN HERE. Margin here causes the oval squishing!
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
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
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
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: _neonGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _voidBlack,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DROPDOWN PANEL
// ═══════════════════════════════════════════════════════════════════════

class _NotificationDropdownPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onViewAll;
  final void Function(Map<String, dynamic>)? onDeepLink;
  final VoidCallback? onActionCompleted;

  const _NotificationDropdownPanel({
    required this.onClose,
    this.onViewAll,
    this.onDeepLink,
    this.onActionCompleted,
  });

  @override
  State<_NotificationDropdownPanel> createState() =>
      _NotificationDropdownPanelState();
}

class _NotificationDropdownPanelState
    extends State<_NotificationDropdownPanel> {
  List<OGANotification> _notifications = [];
  bool _isLoading = true;
  final Set<String> _actedOnIds = {};
  final Map<String, String?> _avatarCache = {};
  static const int _maxVisible = 5;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final all = await NotificationService.getAll(limit: 20);
      debugPrint('>>> DROPDOWN: Loaded ${all.length} notifications');
      for (final n in all) {
        final actionable = _isActionableType(n.type);
        debugPrint(
          '>>>   [${n.id.substring(0, 8)}] '
          'type=${n.type}  isRead=${n.isRead}  '
          'actionable=$actionable  sender=${n.senderEmail ?? "null"}',
        );
      }
      // Batch-fetch sender avatars
      final emails = all
          .where((n) => n.senderEmail != null)
          .map((n) => n.senderEmail!)
          .toSet()
          .toList();
      if (emails.isNotEmpty) {
        try {
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select('email, avatar_url, full_name')
              .inFilter('email', emails);
          for (final p in profiles) {
            _avatarCache[p['email'] as String] = p['avatar_url'] as String?;
          }
        } catch (e) {
          debugPrint('!!! Avatar fetch error: $e');
        }
      }
      if (mounted) {
        setState(() {
          _notifications = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('!!! NotificationDropdown: load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returns true if this notification type supports accept/decline.
  bool _isActionableType(String type) {
    return type == 'trade_proposed' ||
        type == 'lend_proposed' ||
        type == 'friend_request' ||
        type == 'lend_requested';
  }

  /// Determines whether to show accept/decline buttons.
  /// Buttons show ONLY when: unread + actionable type + not acted on.
  bool _shouldShowButtons(OGANotification n) {
    final isUnread = !n.isRead;
    final isActionable = _isActionableType(n.type);
    final notActedOn = !_actedOnIds.contains(n.id);
    final show = isUnread && isActionable && notActedOn;

    // Debug: trace why buttons do / don't show
    if (isActionable) {
      debugPrint(
        '>>> showButtons: type=${n.type} isRead=${n.isRead} '
        'actedOn=${_actedOnIds.contains(n.id)} => show=$show',
      );
    }
    return show;
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
          _buildHeader(unreadCount),
          const Divider(color: _ironGrey, height: 1),
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
          if (!_isLoading && _notifications.isNotEmpty) ...[
            const Divider(color: _ironGrey, height: 1),
            _buildFooter(),
          ],
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────

  Widget _buildHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        children: [
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
          if (unreadCount > 0)
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

  // ─── NOTIFICATION ROW ────────────────────────────────────────
  //
  // KEY FIX (v3): Two completely separate widget branches:
  //   1. Actionable (unread + trade/lend/friend_request) →
  //      NO tap handler on the row. Only buttons fire actions.
  //   2. Non-actionable / already acted on / already read →
  //      InkWell wraps the row → marks read + deep-links.
  //
  // Previous v2 used GestureDetector(onTap: null, behavior: opaque)
  // which was STILL intercepting taps from the ElevatedButton children
  // because opaque means "I handle all hits in my bounds".

  Widget _buildNotificationRow(OGANotification notification) {
    final isUnread = !notification.isRead;
    final showButtons = _shouldShowButtons(notification);

    if (showButtons) {
      // ─── ACTIONABLE: info row tappable for detail, buttons stay ───
      return Container(
        color: _neonGreen.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _openDetailSheet(notification),
              child: _buildInfoRow(notification, isUnread: true),
            ),
            const SizedBox(height: 8),
            _buildInlineActions(notification),
          ],
        ),
      );
    } else {
      // ─── NON-ACTIONABLE: tap marks read + deep-links ──────
      return InkWell(
        onTap: () => _handleTap(notification),
        child: Container(
          color: isUnread
              ? _neonGreen.withValues(alpha: 0.03)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: _buildInfoRow(notification, isUnread: isUnread),
        ),
      );
    }
  }

  /// The icon + title + message + timestamp row (shared).
  Widget _buildInfoRow(OGANotification notification, {required bool isUnread}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIcon(notification),
        const SizedBox(width: 10),
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
        Text(
          _timeAgo(notification.createdAt),
          style: TextStyle(
            color: _pureWhite.withValues(alpha: 0.2),
            fontSize: 10,
          ),
        ),
      ],
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

    // Sender avatar for actionable items (real image or initial letter)
    if (notification.senderEmail != null &&
        notification.senderEmail!.isNotEmpty &&
        _isActionableType(notification.type)) {
      final avatarUrl = _avatarCache[notification.senderEmail];
      final initial = notification.senderEmail!.substring(0, 1).toUpperCase();
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
      );
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

  // ─── ACCEPT / DECLINE BUTTONS ────────────────────────────────

  Widget _buildInlineActions(OGANotification notification) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
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
            height: 30,
            child: OutlinedButton(
              onPressed: () => _handleDecline(notification),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pureWhite.withValues(alpha: 0.5),
                side: const BorderSide(color: _ironGrey),
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

  // ─── EMPTY STATE ─────────────────────────────────────────────

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

  // ─── FOOTER ──────────────────────────────────────────────────

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () {
        final navigator = Navigator.of(context);
        widget.onClose();
        if (widget.onViewAll != null) {
          widget.onViewAll!();
        } else {
          navigator.pushNamed('/activity');
        }
      },
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

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Closes dropdown first, then opens detail sheet.
  void _openDetailSheet(OGANotification notification) {
    if (!mounted) return;
    widget.onClose(); // Close dropdown so sheet is not obscured on mobile
    // Small delay to let overlay remove before sheet animates in
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        NotificationDetailSheet.show(
          context,
          notification: notification,
          onAccept: () => _handleAccept(notification),
          onDecline: () => _handleDecline(notification),
        );
      }
    });
  }

  Future<void> _handleTap(OGANotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
      _updateLocalReadState(notification.id);
    }

    // Handle system notifications: navigate directly, don't open detail sheet
    if (notification.type == 'system') {
      widget.onClose();
      if (notification.actionUrl == '/admin') {
        Future.delayed(const Duration(milliseconds: 50), () {
          Navigator.pushNamed(context, '/admin', arguments: {'initialTab': 1});
        });
      }
      return;
    }

    // Close dropdown first so sheet is not obscured on mobile
    widget.onClose();
    await Future.delayed(const Duration(milliseconds: 50));
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
      '>>> ACCEPT tapped: type=${notification.type} '
      'refId=${notification.referenceId}',
    );

    // Immediately hide buttons via _actedOnIds
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
        successMsg = 'Lend request approved! Character sent.';
      case 'friend_request':
        final ok = await FriendService.acceptRequest(notification.referenceId);
        result = ok ? 'success' : 'Failed to accept friend request';
        successMsg = 'Friend request accepted!';
      default:
        return;
    }

    if (!mounted) return;

    if (result == 'success') {
      // 1. Mark read in DB
      await NotificationService.markRead(notification.id);
      NotificationService.decrementUnread();
      // 2. Update local state (buttons disappear)
      _updateLocalReadState(notification.id);
      // 3. Re-fetch notifications to get fresh data
      await _loadNotifications();
      // 4. Tell dashboard to reload ownership / library
      widget.onActionCompleted?.call();
      // 5. Show success snackbar
      _showSnackBar(successMsg, isSuccess: true);
      debugPrint('>>> ACCEPT success: $successMsg');
    } else {
      // Rollback — show buttons again
      setState(() => _actedOnIds.remove(notification.id));
      _showSnackBar(result, isSuccess: false);
      debugPrint('>>> ACCEPT failed: $result');
    }
  }

  Future<void> _handleDecline(OGANotification notification) async {
    debugPrint(
      '>>> DECLINE tapped: type=${notification.type} '
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
      debugPrint('>>> DECLINE success: $successMsg');
    } else {
      setState(() => _actedOnIds.remove(notification.id));
      _showSnackBar(result, isSuccess: false);
      debugPrint('>>> DECLINE failed: $result');
    }
  }

  /// Locally flip a notification to isRead=true so buttons vanish.
  void _updateLocalReadState(String notificationId) {
    if (!mounted) return;
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
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
