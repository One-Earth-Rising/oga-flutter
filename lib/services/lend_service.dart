// ═══════════════════════════════════════════════════════════════════
// LEND SERVICE — Sprint 13 v2
// Temporary character delegation with time-locked returns.
//
// v2 CHANGES:
//   - Added requestLend() — borrower asks owner to lend their character
//   - Added acceptLendRequest() — owner approves a borrow request
//   - Added declineLendRequest() — owner declines a borrow request
//   - New lend status: 'requested' (borrower-initiated, awaiting owner approval)
//   - Existing statuses: 'pending' (lender-initiated), 'active', 'declined',
//     'returned', 'recalled', 'expired'
//
// Two flows:
//   LENDER-INITIATED: proposeLend → borrower sees lend_proposed → acceptLend
//   BORROWER-INITIATED: requestLend → owner sees lend_requested → acceptLendRequest
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
  bool get isRequested => status == 'requested';

  Duration? get timeRemaining {
    if (returnDueAt == null) return null;
    final remaining = returnDueAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

// ═══════════════════════════════════════════════════════════════════
// LEND SERVICE
// ═══════════════════════════════════════════════════════════════════

class LendService {
  LendService._();
  static final _supabase = Supabase.instance.client;

  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ─────────────────────────────────────────────────────────────
  // LENDER-INITIATED: "I own this, I'll lend it to you"
  // ─────────────────────────────────────────────────────────────

  static Future<String> proposeLend({
    required String borrowerEmail,
    required String characterId,
    int durationHours = 168,
    int? durationDays,
    String? message,
  }) async {
    final actualHours = durationDays != null
        ? durationDays * 24
        : durationHours;
    final email = _currentEmail;
    if (email == null) return 'Not logged in';
    if (borrowerEmail == email) return 'Cannot lend to yourself';

    try {
      final friendship = await _supabase
          .from('friendships')
          .select('id')
          .eq('status', 'accepted')
          .or(
            'and(requester_email.eq.$email,receiver_email.eq.$borrowerEmail),'
            'and(requester_email.eq.$borrowerEmail,receiver_email.eq.$email)',
          )
          .limit(1)
          .maybeSingle();

      if (friendship == null) return 'You must be friends to lend';

      final ownership = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', email)
          .eq('character_id', characterId)
          .eq('status', 'active')
          .eq('is_lent_out', false)
          .limit(1)
          .maybeSingle();

      if (ownership == null)
        return 'You don\'t own this character or it\'s already lent out';

      final activeLend = await _supabase
          .from('lends')
          .select('id')
          .eq('lender_email', email)
          .eq('character_id', characterId)
          .inFilter('status', ['pending', 'requested', 'active'])
          .limit(1)
          .maybeSingle();

      if (activeLend != null)
        return 'This character already has a pending or active lend';

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

      await _supabase.from('notifications').insert({
        'recipient_email': borrowerEmail,
        'type': 'lend_proposed',
        'reference_id': lendRow['id'],
        'reference_type': 'lend',
        'message': '${email.split('@').first} wants to lend you a character!',
        'sender_email': email,
        'category': 'lend',
        'action_url': '/lend-inbox',
      });

      debugPrint('✅ LendService: lend proposed → $borrowerEmail');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.proposeLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BORROWER-INITIATED: "You own this, please lend it to me"
  // ─────────────────────────────────────────────────────────────

  /// Request to borrow a friend's character.
  /// Creates a lend with status='requested' (vs 'pending' for lender-initiated).
  /// Owner receives lend_requested notification with ACCEPT/DECLINE.
  static Future<String> requestLend({
    required String ownerEmail,
    required String characterId,
    int durationDays = 7,
    String? message,
  }) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';
    if (ownerEmail == email) return 'Cannot request from yourself';

    try {
      // Verify friendship
      final friendship = await _supabase
          .from('friendships')
          .select('id')
          .eq('status', 'accepted')
          .or(
            'and(requester_email.eq.$email,receiver_email.eq.$ownerEmail),'
            'and(requester_email.eq.$ownerEmail,receiver_email.eq.$email)',
          )
          .limit(1)
          .maybeSingle();

      if (friendship == null) return 'You must be friends to request a lend';

      // Verify the OWNER actually owns this character
      final ownership = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', ownerEmail)
          .eq('character_id', characterId)
          .eq('status', 'active')
          .eq('is_lent_out', false)
          .limit(1)
          .maybeSingle();

      if (ownership == null) {
        return 'This character is not available for lending';
      }

      // Check no existing request/lend for this character from us
      final existing = await _supabase
          .from('lends')
          .select('id')
          .eq('lender_email', ownerEmail)
          .eq('borrower_email', email)
          .eq('character_id', characterId)
          .inFilter('status', ['pending', 'requested', 'active'])
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        return 'You already have a pending request for this character';
      }

      // Create the lend with status='requested'
      final insertData = <String, dynamic>{
        'lender_email': ownerEmail,
        'borrower_email': email,
        'character_id': characterId,
        'duration_hours': durationDays * 24,
        'ownership_id': ownership['id'],
        'status': 'requested',
      };
      if (message != null && message.isNotEmpty) {
        insertData['message'] = message;
      }

      final lendRow = await _supabase
          .from('lends')
          .insert(insertData)
          .select('id')
          .single();

      // Notify the OWNER
      await _supabase.from('notifications').insert({
        'recipient_email': ownerEmail,
        'type': 'lend_requested',
        'reference_id': lendRow['id'],
        'reference_type': 'lend',
        'message': '${email.split('@').first} wants to borrow your character!',
        'sender_email': email,
        'category': 'lend',
        'action_url': '/lend-inbox',
      });

      debugPrint('✅ LendService: lend requested from $ownerEmail');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.requestLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ACCEPT / DECLINE
  // ─────────────────────────────────────────────────────────────

  /// Accept a lend offer (BORROWER action — lender-initiated flow).
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

      await _supabase
          .from('lends')
          .update({
            'status': 'active',
            'accepted_at': now.toIso8601String(),
            'return_due_at': returnDue.toIso8601String(),
          })
          .eq('id', lendId);

      await _supabase
          .from('character_ownership')
          .update({'is_lent_out': true})
          .eq('id', lend['ownership_id']);

      await _supabase.from('notifications').insert({
        'recipient_email': lend['lender_email'],
        'type': 'lend_accepted',
        'reference_id': lendId,
        'reference_type': 'lend',
        'message': '${email.split('@').first} accepted your character lend!',
        'sender_email': email,
        'category': 'lend',
        'action_url': '/lend-inbox',
      });

      debugPrint('✅ LendService: lend accepted → $lendId');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.acceptLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Accept a lend REQUEST (OWNER action — borrower-initiated flow).
  static Future<String> acceptLendRequest(String lendId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      final lend = await _supabase
          .from('lends')
          .select()
          .eq('id', lendId)
          .eq('lender_email', email)
          .eq('status', 'requested')
          .maybeSingle();

      if (lend == null) return 'Request not found or already resolved';

      final now = DateTime.now();
      final returnDue = now.add(Duration(hours: lend['duration_hours'] as int));

      await _supabase
          .from('lends')
          .update({
            'status': 'active',
            'accepted_at': now.toIso8601String(),
            'return_due_at': returnDue.toIso8601String(),
          })
          .eq('id', lendId);

      await _supabase
          .from('character_ownership')
          .update({'is_lent_out': true})
          .eq('id', lend['ownership_id']);

      await _supabase.from('notifications').insert({
        'recipient_email': lend['borrower_email'],
        'type': 'lend_accepted',
        'reference_id': lendId,
        'reference_type': 'lend',
        'message':
            '${email.split('@').first} approved your lend request! Character is now in your library.',
        'sender_email': email,
        'category': 'lend',
        'action_url': '/lend-inbox',
      });

      debugPrint('✅ LendService: lend request accepted → $lendId');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.acceptLendRequest error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Decline a lend offer (BORROWER action — lender-initiated flow).
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

      await _supabase.from('notifications').insert({
        'recipient_email': lend['lender_email'],
        'type': 'lend_declined',
        'reference_id': lendId,
        'reference_type': 'lend',
        'message': 'Your lend offer was declined.',
        'sender_email': email,
        'category': 'lend',
        'action_url': '/lend-inbox',
      });

      debugPrint('✅ LendService: lend declined → $lendId');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.declineLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Decline a lend REQUEST (OWNER action — borrower-initiated flow).
  static Future<String> declineLendRequest(String lendId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      final lend = await _supabase
          .from('lends')
          .select()
          .eq('id', lendId)
          .eq('lender_email', email)
          .eq('status', 'requested')
          .maybeSingle();

      if (lend == null) return 'Request not found or already resolved';

      await _supabase
          .from('lends')
          .update({'status': 'declined'})
          .eq('id', lendId);

      await _supabase.from('notifications').insert({
        'recipient_email': lend['borrower_email'],
        'type': 'lend_declined',
        'reference_id': lendId,
        'reference_type': 'lend',
        'message': 'Your lend request was declined.',
        'sender_email': email,
        'category': 'lend',
        'action_url': '/lend-inbox',
      });

      debugPrint('✅ LendService: lend request declined → $lendId');
      return 'success';
    } catch (e) {
      debugPrint('❌ LendService.declineLendRequest error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Return / Recall ──────────────────────────────────────

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

  static Future<String> recallLend(String lendId) async {
    try {
      // Fetch lend details before RPC so we can notify borrower
      final lend = await _supabase
          .from('lends')
          .select('borrower_email, character_id, lender_email')
          .eq('id', lendId)
          .maybeSingle();

      final result = await _supabase.rpc(
        'return_lend',
        params: {'p_lend_id': lendId},
      );
      final message = result?.toString() ?? 'Unknown error';
      if (message == 'success') {
        debugPrint('✅ LendService: recalled → $lendId');
        if (lend != null) {
          final borrowerEmail = lend['borrower_email'] as String;
          final characterId = lend['character_id'] as String;
          final lenderEmail = lend['lender_email'] as String;
          await _supabase.from('notifications').insert({
            'recipient_email': borrowerEmail,
            'type': 'lend_recalled',
            'reference_id': lendId,
            'reference_type': 'lend',
            'message':
                '${lenderEmail.split('@').first} recalled $characterId — it has been removed from your library.',
            'sender_email': lenderEmail,
            'category': 'lend',
            'action_url': '/dashboard',
          });
        }
      }
      return message;
    } catch (e) {
      debugPrint('❌ LendService.recallLend error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Query Lends ──────────────────────────────────────────

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

  // ─── Convenience aliases ──────────────────────────────────

  static Future<List<Lend>> getActiveBorrowing() => getActiveBorrowed();
  static Future<List<Lend>> getActiveLending() => getActiveLentOut();

  static Future<List<Lend>> getPendingRequests() async {
    final email = _currentEmail;
    if (email == null) return [];
    final all = await getMyLends(status: 'pending');
    return all.where((l) => l.borrowerEmail == email).toList();
  }

  static Future<List<Lend>> getLendHistory() async {
    final all = await getMyLends();
    return all
        .where(
          (l) =>
              l.status != 'pending' &&
              l.status != 'active' &&
              l.status != 'requested',
        )
        .toList();
  }

  static Future<String> returnLend(String lendId) => returnEarly(lendId);

  /// Returns active borrows enriched with character catalog data.
  /// Use this to populate the borrower's dashboard cards.
  static Future<List<Map<String, dynamic>>>
  getActiveBorrowedWithCharacters() async {
    final email = _currentEmail;
    if (email == null) return [];
    try {
      final rows = await _supabase
          .from('lends')
          .select('''
            id, lender_email, borrower_email, character_id,
            duration_hours, status, accepted_at, return_due_at
          ''')
          .eq('borrower_email', email)
          .eq('status', 'active');

      return rows
          .map<Map<String, dynamic>>(
            (row) => {
              ...row,
              'display_mode': 'borrowed', // flag for dashboard card rendering
            },
          )
          .toList();
    } catch (e) {
      debugPrint('❌ LendService.getActiveBorrowedWithCharacters error: $e');
      return [];
    }
  }
}
