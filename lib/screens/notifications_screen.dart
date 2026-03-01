// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATIONS SCREEN — Sprint 12
// Lists all notifications. Trade/lend actions inline.
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import 'trade_inbox_screen.dart';
import 'lend_inbox_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ─── Heimdal palette ─────────────────────────────────
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) return;

      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_email', email)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load notifications error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String notifId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('id', notifId);
      NotificationService.decrementUnread();
    } catch (e) {
      debugPrint('❌ markAsRead error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) return;

      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('user_email', email)
          .eq('read', false);

      NotificationService.resetUnread();
      _loadNotifications();
    } catch (e) {
      debugPrint('❌ markAllAsRead error: $e');
    }
  }

  void _navigateToAction(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? '';
    _markAsRead(notif['id'].toString());

    if (type.startsWith('trade_')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TradeInboxScreen()),
      );
    } else if (type.startsWith('lend_')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LendInboxScreen()),
      );
    }
  }

  // ─── Notification type → display config ────────────────
  _NotifDisplay _getDisplay(String type) {
    switch (type) {
      case 'trade_proposed':
        return _NotifDisplay(
          icon: Icons.swap_horiz,
          color: neonGreen,
          label: 'TRADE REQUEST',
        );
      case 'trade_accepted':
        return _NotifDisplay(
          icon: Icons.check_circle_outline,
          color: neonGreen,
          label: 'TRADE ACCEPTED',
        );
      case 'trade_declined':
        return _NotifDisplay(
          icon: Icons.cancel_outlined,
          color: Colors.red.shade400,
          label: 'TRADE DECLINED',
        );
      case 'trade_cancelled':
        return _NotifDisplay(
          icon: Icons.undo,
          color: Colors.orange.shade400,
          label: 'TRADE CANCELLED',
        );
      case 'lend_proposed':
        return _NotifDisplay(
          icon: Icons.schedule_send,
          color: Colors.cyan.shade300,
          label: 'LEND REQUEST',
        );
      case 'lend_accepted':
        return _NotifDisplay(
          icon: Icons.check_circle_outline,
          color: Colors.cyan.shade300,
          label: 'LEND ACCEPTED',
        );
      case 'lend_returned':
        return _NotifDisplay(
          icon: Icons.keyboard_return,
          color: neonGreen,
          label: 'LEND RETURNED',
        );
      case 'lend_recalled':
        return _NotifDisplay(
          icon: Icons.replay,
          color: Colors.orange.shade400,
          label: 'LEND RECALLED',
        );
      default:
        return _NotifDisplay(
          icon: Icons.info_outline,
          color: Colors.white70,
          label: type.toUpperCase().replaceAll('_', ' '),
        );
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().toUtc().difference(date.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: voidBlack,
      appBar: AppBar(
        backgroundColor: voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'MARK ALL READ',
                style: TextStyle(
                  color: neonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : _notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              color: neonGreen,
              backgroundColor: deepCharcoal,
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationTile(_notifications[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'NO NOTIFICATIONS YET',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trade and lend requests will appear here',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? '';
    final message = notif['message'] as String? ?? '';
    final isRead = notif['read'] as bool? ?? false;
    final display = _getDisplay(type);
    final timeStr = _timeAgo(notif['created_at']?.toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? deepCharcoal : deepCharcoal.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? ironGrey : display.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToAction(notif),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: display.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(display.icon, color: display.color, size: 22),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            display.label,
                            style: TextStyle(
                              color: display.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: isRead ? Colors.white60 : Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unread dot
                if (!isRead)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: neonGreen,
                        shape: BoxShape.circle,
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

class _NotifDisplay {
  final IconData icon;
  final Color color;
  final String label;

  const _NotifDisplay({
    required this.icon,
    required this.color,
    required this.label,
  });
}
