// ═══════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE — Sprint 12
// Realtime notifications via Supabase Realtime subscription.
// Provides stream-based unread count for badge updates.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents an in-app notification.
class OGANotification {
  final String id;
  final String recipientEmail;
  final String type;
  final String referenceId;
  final String referenceType;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  const OGANotification({
    required this.id,
    required this.recipientEmail,
    required this.type,
    required this.referenceId,
    this.referenceType = 'trade',
    this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory OGANotification.fromMap(Map<String, dynamic> map) {
    return OGANotification(
      id: map['id']?.toString() ?? '',
      recipientEmail: map['recipient_email'] ?? '',
      type: map['type'] ?? '',
      referenceId: map['reference_id']?.toString() ?? '',
      referenceType: map['reference_type'] ?? 'trade',
      message: map['message'] as String?,
      isRead: map['is_read'] ?? false,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Friendly display title based on notification type.
  String get title {
    switch (type) {
      case 'trade_proposed':
        return 'NEW TRADE PROPOSAL';
      case 'trade_accepted':
        return 'TRADE COMPLETED';
      case 'trade_declined':
        return 'TRADE DECLINED';
      case 'trade_cancelled':
        return 'TRADE CANCELLED';
      case 'lend_proposed':
        return 'CHARACTER LEND OFFER';
      case 'lend_accepted':
        return 'LEND ACCEPTED';
      case 'lend_returned':
        return 'CHARACTER RETURNED';
      case 'lend_recalled':
        return 'LEND RECALLED';
      case 'lend_expiring_soon':
        return 'LEND EXPIRING SOON';
      case 'character_granted':
        return 'NEW CHARACTER';
      default:
        return 'NOTIFICATION';
    }
  }

  /// Icon name suggestion for each notification type.
  String get iconType {
    switch (type) {
      case 'trade_proposed':
      case 'trade_accepted':
      case 'trade_declined':
      case 'trade_cancelled':
        return 'trade';
      case 'lend_proposed':
      case 'lend_accepted':
      case 'lend_returned':
      case 'lend_recalled':
      case 'lend_expiring_soon':
        return 'lend';
      case 'character_granted':
        return 'grant';
      default:
        return 'default';
    }
  }
}

class NotificationService {
  static final _supabase = Supabase.instance.client;
  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ─── Realtime subscription ────────────────────────────────
  static RealtimeChannel? _channel;
  static final _notificationController =
      StreamController<OGANotification>.broadcast();
  static final _unreadCountController = StreamController<int>.broadcast();
  static int _unreadCount = 0;

  /// Stream of new notifications (Realtime).
  static Stream<OGANotification> get onNewNotification =>
      _notificationController.stream;

  /// Stream of unread count changes.
  static Stream<int> get onUnreadCountChanged => _unreadCountController.stream;

  /// Current unread count (synchronous access).
  static int get unreadCount => _unreadCount;

  // ─── Init / Dispose ───────────────────────────────────────

  /// Initialize Realtime subscription for the current user.
  /// Call this after successful authentication.
  static Future<void> init() async {
    final email = _currentEmail;
    if (email == null) return;

    // Clean up any existing subscription
    await dispose();

    // Fetch initial unread count
    await _refreshUnreadCount();

    // Subscribe to new notifications
    _channel = _supabase
        .channel('notifications:$email')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trade_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_email',
            value: email,
          ),
          callback: (payload) {
            debugPrint('🔔 NotificationService: new notification');
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final notification = OGANotification.fromMap(newRecord);
              _notificationController.add(notification);
              _unreadCount++;
              _unreadCountController.add(_unreadCount);
            }
          },
        )
        .subscribe();

    debugPrint(
      '✅ NotificationService: Realtime subscription active for $email',
    );
  }

  /// Clean up subscription (on logout or dispose).
  static Future<void> dispose() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
      debugPrint('🔕 NotificationService: subscription removed');
    }
  }

  // ─── Query Notifications ──────────────────────────────────

  /// Get all unread notifications.
  static Future<List<OGANotification>> getUnread() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('trade_notifications')
          .select()
          .eq('recipient_email', email)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return rows
          .map<OGANotification>((row) => OGANotification.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('❌ NotificationService.getUnread error: $e');
      return [];
    }
  }

  /// Get all notifications (read + unread), with optional limit.
  static Future<List<OGANotification>> getAll({int limit = 50}) async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('trade_notifications')
          .select()
          .eq('recipient_email', email)
          .order('created_at', ascending: false)
          .limit(limit);

      return rows
          .map<OGANotification>((row) => OGANotification.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('❌ NotificationService.getAll error: $e');
      return [];
    }
  }

  /// Get unread count.
  static Future<int> getUnreadCount() async {
    final email = _currentEmail;
    if (email == null) return 0;

    try {
      final rows = await _supabase
          .from('trade_notifications')
          .select('id')
          .eq('recipient_email', email)
          .eq('is_read', false);

      _unreadCount = rows.length;
      _unreadCountController.add(_unreadCount);
      return _unreadCount;
    } catch (e) {
      debugPrint('❌ NotificationService.getUnreadCount error: $e');
      return 0;
    }
  }

  // ─── Mark Read ────────────────────────────────────────────

  /// Mark a single notification as read.
  static Future<void> markRead(String notificationId) async {
    try {
      await _supabase
          .from('trade_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      await _refreshUnreadCount();
      debugPrint('✅ NotificationService: marked read → $notificationId');
    } catch (e) {
      debugPrint('❌ NotificationService.markRead error: $e');
    }
  }

  /// Mark all notifications as read.
  static Future<void> markAllRead() async {
    final email = _currentEmail;
    if (email == null) return;

    try {
      await _supabase
          .from('trade_notifications')
          .update({'is_read': true})
          .eq('recipient_email', email)
          .eq('is_read', false);

      _unreadCount = 0;
      _unreadCountController.add(0);
      debugPrint('✅ NotificationService: all marked read');
    } catch (e) {
      debugPrint('❌ NotificationService.markAllRead error: $e');
    }
  }

  // ─── Private helpers ──────────────────────────────────────

  static Future<void> _refreshUnreadCount() async {
    _unreadCount = await getUnreadCount();
  }
}
