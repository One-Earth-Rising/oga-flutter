import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for submitting and retrieving user feedback.
class FeedbackService {
  static final _supabase = Supabase.instance.client;

  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  /// Submit feedback to Supabase.
  /// Returns true on success, false on failure.
  static Future<bool> submit({
    required String category,
    required String message,
    String? pageContext,
    String? screenshotUrl,
    String? deviceInfo,
  }) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      await _supabase.from('feedback').insert({
        'user_email': email,
        'category': category,
        'message': message.trim(),
        'page_context': pageContext,
        'screenshot_url': screenshotUrl,
        'device_info': deviceInfo,
      });

      debugPrint(
        '✅ Feedback submitted: [$category] ${message.substring(0, message.length.clamp(0, 50))}...',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      return false;
    }
  }

  /// Get the current user's feedback history.
  static Future<List<FeedbackEntry>> getMyFeedback() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('feedback')
          .select()
          .eq('user_email', email)
          .order('created_at', ascending: false);

      return (rows as List).map((r) => FeedbackEntry.fromMap(r)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching feedback: $e');
      return [];
    }
  }
}

/// Feedback entry data model.
class FeedbackEntry {
  final int id;
  final String category;
  final String message;
  final String? pageContext;
  final String status;
  final DateTime createdAt;

  const FeedbackEntry({
    required this.id,
    required this.category,
    required this.message,
    this.pageContext,
    required this.status,
    required this.createdAt,
  });

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    return FeedbackEntry(
      id: map['id'] as int,
      category: map['category'] as String? ?? 'other',
      message: map['message'] as String? ?? '',
      pageContext: map['page_context'] as String?,
      status: map['status'] as String? ?? 'new',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Human-readable category label
  String get categoryLabel {
    switch (category) {
      case 'bug':
        return '🐛 Bug Report';
      case 'feature':
        return '💡 Feature Request';
      case 'ux':
        return '🎨 UX Feedback';
      default:
        return '📝 Other';
    }
  }

  /// Status color
  Color get statusColor {
    switch (status) {
      case 'new':
        return const Color(0xFF39FF14);
      case 'reviewed':
        return const Color(0xFF2563EB);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return Colors.white38;
      default:
        return Colors.white24;
    }
  }
}
