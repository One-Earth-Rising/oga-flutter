// ═══════════════════════════════════════════════════════════════════
// NOTIFICATION BELL WIDGET — Sprint 13
// ⚡ icon with green dot indicator for unread notifications.
// Self-contained: listens to NotificationService streams.
//
// Usage:
//   NotificationBellWidget(onTap: () => Navigator.push(...ActivityScreen))
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

const Color _neonGreen = Color(0xFF39FF14);
const Color _deepCharcoal = Color(0xFF121212);
const Color _ironGrey = Color(0xFF2C2C2C);
const Color _pureWhite = Color(0xFFFFFFFF);

class NotificationBellWidget extends StatefulWidget {
  final VoidCallback onTap;

  const NotificationBellWidget({super.key, required this.onTap});

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

  @override
  void initState() {
    super.initState();

    // Initial count
    _unreadCount = NotificationService.unreadCount;

    // Listen for count changes
    _countSub = NotificationService.unreadCountStream.listen((count) {
      if (mounted) setState(() => _unreadCount = count);
    });

    // Pulse animation when new notification arrives
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: hasUnread
                ? _neonGreen.withValues(alpha: 0.08)
                : _deepCharcoal.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: hasUnread
                  ? _neonGreen.withValues(alpha: 0.25)
                  : _ironGrey.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ⚡ icon
              Icon(
                Icons.bolt,
                color: hasUnread
                    ? _neonGreen
                    : _pureWhite.withValues(alpha: 0.5),
                size: 18,
              ),
              // Green dot indicator
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
    );
  }
}
