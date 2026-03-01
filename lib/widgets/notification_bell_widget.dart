// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION BELL WIDGET — Sprint 12
// AppBar icon with unread badge. Taps open NotificationsScreen.
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

class NotificationBellWidget extends StatefulWidget {
  const NotificationBellWidget({super.key});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int _lastCount = 0;

  // ─── Heimdal palette ─────────────────────────────────
  static const Color neonGreen = Color(0xFF39FF14);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.03), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
    _shakeController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onCountChanged(int newCount) {
    if (newCount > _lastCount && newCount > 0) {
      _shakeController.forward(from: 0);
    }
    _lastCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.unreadCountStream,
      initialData: NotificationService.unreadCount,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        _onCountChanged(count);

        return Transform.rotate(
          angle: _shakeAnimation.value,
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: neonGreen,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const NotificationsScreen(),
                  transitionsBuilder: (_, anim, __, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              );
            },
            tooltip: count > 0 ? '$count notifications' : 'Notifications',
          ),
        );
      },
    );
  }
}
