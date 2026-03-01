// ═══════════════════════════════════════════════════════════════════
// LEND SERVICE — Sprint 12
// Temporary character delegation with time-locked returns.
// Auto-return handled via n8n scheduled workflow + return_lend() RPC.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a lend between two users.
class Lend {
  final String id;
  final String lenderEmail;
  final String borrowerEmail;
  final String characterId;
  final int durationHours;
  final String? message;
  final String status;
  final DateTime proposedAt;
  final DateTime? acceptedAt;
  final DateTime? returnDueAt;
  final DateTime? returnedAt;

  const Lend({
    required this.id,
    required this.lenderEmail,
    required this.borrowerEmail,
    required this.characterId,
    required this.durationHours,
    this.message,
    required this.status,
    required this.proposedAt,
    this.acceptedAt,
    this.returnDueAt,
    this.returnedAt,
  });

  factory Lend.fromMap(Map<String, dynamic> map) {
    return Lend(
      id: map['id']?.toString() ?? '',
      lenderEmail: map['lender_email'] ?? '',
      borrowerEmail: map['borrower_email'] ?? '',
      characterId: map['character_id'] ?? '',
      durationHours: map['duration_hours'] ?? 168,
      message: map['message'] as String?,
      status: map['status'] ?? 'pending',
      proposedAt:
          DateTime.tryParse(map['proposed_at']?.toString() ?? '') ??
          DateTime.now(),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.tryParse(map['accepted_at'].toString())
          : null,
      returnDueAt: map['return_due_at'] != null
          ? DateTime.tryParse(map['return_due_at'].toString())
          : null,
      returnedAt: map['returned_at'] != null
          ? DateTime.tryParse(map['returned_at'].toString())
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isOverdue =>
      isActive && returnDueAt != null && DateTime.now().isAfter(returnDueAt!);

  Duration get timeRemaining =>
      returnDueAt?.difference(DateTime.now()) ?? Duration.zero;

  String get durationLabel {
    if (durationHours < 24) return '${durationHours}h';
    final days = durationHours ~/ 24;
    return '${days}d';
  }
}

class LendService {
  static final _supabase = Supabase.instance.client;
  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ─── Propose a Lend ───────────────────────────────────────

  /// Offer to lend a character to a friend.
  /// Returns 'success' or an error message.
  static Future<String> proposeLend({
    required String borrowerEmail,
    required String characterId,
    int durationHours = 168, // 7 days default
    int? durationDays, // UI convenience — overrides durationHours
    String? message,
  }) async {
    final actualHours = durationDays != null
        ? durationDays * 24
        : durationHours;
    final email = _currentEmail;
    if (email == null) return 'Not logged in';
    if (borrowerEmail == email) return 'Cannot lend to yourself';

    try {
      // Verify friendship
      final friendship = await _supabase
          .from('friendships')
          .select('id')
          .eq('status', 'accepted')
          .or(
            'and(requester_email.eq.$email,receiver_email.eq.$borrowerEmail),'
            'and(requester_email.eq.$borrowerEmail,receiver_email.eq.$email)',
          )
          .maybeSingle();

      if (friendship == null) return 'You must be friends to lend';

      // Verify ownership (active, not already lent out)
      final ownership = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', email)
          .eq('character_id', characterId)
          .eq('status', 'active')
          .eq('is_lent_out', false)
          .maybeSingle();

      if (ownership == null)
        return 'You don\'t own this character or it\'s already lent out';

      // Check no active lend for this character
      final activeLend = await _supabase
          .from('lends')
          .select('id')
          .eq('lender_email', email)
          .eq('character_id', characterId)
          .inFilter('status', ['pending', 'active'])
          .maybeSingle();

      if (activeLend != null)
        return 'This character already has a pending or active lend';

      // Create the lend
      final insertData = <String, dynamic>{
        'lender_email': email,
        'borrower_email': borrowerEmail,
        'character_id': characterId,
        'duration_hours': actualHours,
        'ownership_id': ownership['id'],
      };
      if (message != null && message.isNotEmpty) {
        insertData['message'] = message;
      }
      final lendRow = await _supabase
          .from('lends')
          .insert(insertData)
          .select('id')
          .single();

      // Notify borrower
      await _supabase.from('trade_notifications').insert({
        'recipient_email': borrowerEmail,
        'type': 'lend_proposed',
        'reference_id': lendRow['id'],
        'reference_type': 'lend',
        'message': '${email.split('@').first} wants to lend you a character!',
      });

      debugPrint('✅ LendService: lend proposed → $borrowerEmail');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.proposeLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Accept a Lend ────────────────────────────────────────

  /// Accept a lend offer (borrower action).
  static Future<String> acceptLend(String lendId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      final lend = await _supabase
          .from('lends')
          .select()
          .eq('id', lendId)
          .eq('borrower_email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (lend == null) return 'Lend not found or already resolved';

      final now = DateTime.now();
      final returnDue = now.add(Duration(hours: lend['duration_hours'] as int));

      // Activate the lend
      await _supabase
          .from('lends')
          .update({
            'status': 'active',
            'accepted_at': now.toIso8601String(),
            'return_due_at': returnDue.toIso8601String(),
          })
          .eq('id', lendId);

      // Mark the character as lent out
      await _supabase
          .from('character_ownership')
          .update({'is_lent_out': true})
          .eq('id', lend['ownership_id']);

      // Notify lender
      await _supabase.from('trade_notifications').insert({
        'recipient_email': lend['lender_email'],
        'type': 'lend_accepted',
        'reference_id': lendId,
        'reference_type': 'lend',
        'message': '${email.split('@').first} accepted your character lend!',
      });

      debugPrint('✅ LendService: lend accepted → $lendId');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.acceptLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Decline a Lend ───────────────────────────────────────

  /// Decline a lend offer (borrower action).
  static Future<String> declineLend(String lendId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      final lend = await _supabase
          .from('lends')
          .select()
          .eq('id', lendId)
          .eq('borrower_email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (lend == null) return 'Lend not found or already resolved';

      await _supabase
          .from('lends')
          .update({'status': 'declined'})
          .eq('id', lendId);

      // Notify lender
      await _supabase.from('trade_notifications').insert({
        'recipient_email': lend['lender_email'],
        'type': 'lend_declined',
        'reference_id': lendId,
        'reference_type': 'lend',
        'message': 'Your lend offer was declined.',
      });

      debugPrint('✅ LendService: lend declined → $lendId');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.declineLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Return / Recall ──────────────────────────────────────

  /// Return a borrowed character early (borrower action).
  static Future<String> returnEarly(String lendId) async {
    try {
      final result = await _supabase.rpc(
        'return_lend',
        params: {'p_lend_id': lendId},
      );
      final message = result?.toString() ?? 'Unknown error';
      if (message == 'success') {
        debugPrint('✅ LendService: early return → $lendId');
      }
      return message;
    } catch (e) {
      debugPrint('❌ LendService.returnEarly error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Recall a lent character (lender action — early return).
  static Future<String> recallLend(String lendId) async {
    // Same operation — return_lend() handles it from either side
    try {
      final result = await _supabase.rpc(
        'return_lend',
        params: {'p_lend_id': lendId},
      );
      final message = result?.toString() ?? 'Unknown error';
      if (message == 'success') {
        debugPrint('✅ LendService: recalled → $lendId');
      }
      return message;
    } catch (e) {
      debugPrint('❌ LendService.recallLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Query Lends ──────────────────────────────────────────

  /// Get all lends involving the current user.
  static Future<List<Lend>> getMyLends({String? status}) async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      var query = _supabase
          .from('lends')
          .select()
          .or('lender_email.eq.$email,borrower_email.eq.$email');

      if (status != null) {
        query = query.eq('status', status);
      }

      final rows = await query.order('proposed_at', ascending: false);
      return rows.map<Lend>((row) => Lend.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ LendService.getMyLends error: $e');
      return [];
    }
  }

  /// Get characters actively borrowed by current user.
  static Future<List<Lend>> getActiveBorrowed() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('lends')
          .select()
          .eq('borrower_email', email)
          .eq('status', 'active');

      return rows.map<Lend>((row) => Lend.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ LendService.getActiveBorrowed error: $e');
      return [];
    }
  }

  /// Get characters actively lent out by current user.
  static Future<List<Lend>> getActiveLentOut() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('lends')
          .select()
          .eq('lender_email', email)
          .eq('status', 'active');

      return rows.map<Lend>((row) => Lend.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ LendService.getActiveLentOut error: $e');
      return [];
    }
  }

  // ─── Convenience aliases (used by UI screens) ────────────

  /// Alias: get characters user is currently borrowing.
  static Future<List<Lend>> getActiveBorrowing() => getActiveBorrowed();

  /// Alias: get characters user is currently lending out.
  static Future<List<Lend>> getActiveLending() => getActiveLentOut();

  /// Get pending lend requests where current user is the borrower.
  static Future<List<Lend>> getPendingRequests() async {
    final email = _currentEmail;
    if (email == null) return [];
    final all = await getMyLends(status: 'pending');
    return all.where((l) => l.borrowerEmail == email).toList();
  }

  /// Get completed / returned lends involving current user.
  static Future<List<Lend>> getLendHistory() async {
    final all = await getMyLends();
    return all
        .where((l) => l.status != 'pending' && l.status != 'active')
        .toList();
  }

  /// Alias for returnEarly (UI calls it returnLend).
  static Future<String> returnLend(String lendId) => returnEarly(lendId);
}
