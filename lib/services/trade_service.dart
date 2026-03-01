// ═══════════════════════════════════════════════════════════════════
// TRADE SERVICE — Sprint 12
// P2P character trading: propose, accept, decline, cancel.
// Atomic swaps via execute_trade() Postgres function.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a trade between two users.
class Trade {
  final String id;
  final String proposerEmail;
  final String receiverEmail;
  final String offeredCharacterId;
  final String requestedCharacterId;
  final String? message;
  final String status;
  final DateTime proposedAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;

  const Trade({
    required this.id,
    required this.proposerEmail,
    required this.receiverEmail,
    required this.offeredCharacterId,
    required this.requestedCharacterId,
    this.message,
    required this.status,
    required this.proposedAt,
    this.respondedAt,
    required this.expiresAt,
  });

  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id']?.toString() ?? '',
      proposerEmail: map['proposer_email'] ?? '',
      receiverEmail: map['receiver_email'] ?? '',
      offeredCharacterId: map['offered_character_id'] ?? '',
      requestedCharacterId: map['requested_character_id'] ?? '',
      message: map['message'] as String?,
      status: map['status'] ?? 'pending',
      proposedAt:
          DateTime.tryParse(map['proposed_at']?.toString() ?? '') ??
          DateTime.now(),
      respondedAt: map['responded_at'] != null
          ? DateTime.tryParse(map['responded_at'].toString())
          : null,
      expiresAt:
          DateTime.tryParse(map['expires_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isExpired =>
      status == 'expired' || (isPending && DateTime.now().isAfter(expiresAt));

  /// How much time remains before the trade expires.
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Whether the current user is the proposer.
  bool isProposedBy(String email) => proposerEmail == email;

  /// Whether the current user is the receiver.
  bool isReceivedBy(String email) => receiverEmail == email;
}

class TradeService {
  static final _supabase = Supabase.instance.client;
  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ─── Rate limiting ────────────────────────────────────────
  static const _maxPendingTrades = 5;

  // ─── Propose a Trade ──────────────────────────────────────

  /// Create a new trade proposal.
  /// Returns 'success' or an error message.
  static Future<String> proposeTrade({
    required String receiverEmail,
    required String offeredCharacterId,
    required String requestedCharacterId,
    String? message,
  }) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    if (receiverEmail == email) return 'Cannot trade with yourself';
    if (offeredCharacterId == requestedCharacterId) {
      return 'Cannot trade a character for itself';
    }

    try {
      // Rate limit: max pending trades
      final pendingCount = await _supabase
          .from('trades')
          .select('id')
          .eq('proposer_email', email)
          .eq('status', 'pending');

      if (pendingCount.length >= _maxPendingTrades) {
        return 'You have too many pending trades. Cancel or wait for existing trades to resolve.';
      }

      // Verify friendship
      final friendship = await _supabase
          .from('friendships')
          .select('id')
          .eq('status', 'accepted')
          .or(
            'and(requester_email.eq.$email,receiver_email.eq.$receiverEmail),'
            'and(requester_email.eq.$receiverEmail,receiver_email.eq.$email)',
          )
          .maybeSingle();

      if (friendship == null) return 'You must be friends to trade';

      // Verify proposer owns the offered character (active, not lent out)
      final proposerOwns = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', email)
          .eq('character_id', offeredCharacterId)
          .eq('status', 'active')
          .eq('is_lent_out', false)
          .maybeSingle();

      if (proposerOwns == null)
        return 'You don\'t own this character or it\'s currently lent out';

      // Verify receiver owns the requested character
      final receiverOwns = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', receiverEmail)
          .eq('character_id', requestedCharacterId)
          .eq('status', 'active')
          .eq('is_lent_out', false)
          .maybeSingle();

      if (receiverOwns == null)
        return 'Your friend doesn\'t own that character or it\'s currently lent out';

      // Check for duplicate pending trade
      final existingTrade = await _supabase
          .from('trades')
          .select('id')
          .eq('proposer_email', email)
          .eq('receiver_email', receiverEmail)
          .eq('offered_character_id', offeredCharacterId)
          .eq('requested_character_id', requestedCharacterId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingTrade != null)
        return 'You already have a pending trade for this exact swap';

      // Create the trade
      await _supabase.from('trades').insert({
        'proposer_email': email,
        'receiver_email': receiverEmail,
        'offered_character_id': offeredCharacterId,
        'requested_character_id': requestedCharacterId,
        'message': message,
        'proposer_ownership_id': proposerOwns['id'],
        'receiver_ownership_id': receiverOwns['id'],
      });

      // Create notification for receiver
      // (trade_notifications will be created by the insert —
      //  we do it here rather than a trigger for more control)
      final tradeRow = await _supabase
          .from('trades')
          .select('id')
          .eq('proposer_email', email)
          .eq('receiver_email', receiverEmail)
          .eq('offered_character_id', offeredCharacterId)
          .eq('status', 'pending')
          .order('proposed_at', ascending: false)
          .limit(1)
          .single();

      await _supabase.from('trade_notifications').insert({
        'recipient_email': receiverEmail,
        'type': 'trade_proposed',
        'reference_id': tradeRow['id'],
        'reference_type': 'trade',
        'message': 'New trade proposal from ${email.split('@').first}!',
      });

      debugPrint('✅ TradeService: trade proposed → $receiverEmail');
      return 'success';
    } catch (e) {
      debugPrint('❌ TradeService.proposeTrade error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Accept a Trade ───────────────────────────────────────

  /// Accept a pending trade. Calls the atomic swap function.
  /// Returns 'success' or an error message.
  static Future<String> acceptTrade(String tradeId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      // Call the server-side atomic swap function
      final result = await _supabase.rpc(
        'execute_trade',
        params: {'p_trade_id': tradeId},
      );

      final message = result?.toString() ?? 'Unknown error';
      if (message == 'success') {
        debugPrint('✅ TradeService: trade accepted → $tradeId');
      } else {
        debugPrint('⚠️ TradeService: trade failed → $message');
      }
      return message;
    } catch (e) {
      debugPrint('❌ TradeService.acceptTrade error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Decline a Trade ──────────────────────────────────────

  /// Decline a pending trade (receiver action).
  static Future<String> declineTrade(String tradeId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      // Verify this user is the receiver
      final trade = await _supabase
          .from('trades')
          .select()
          .eq('id', tradeId)
          .eq('receiver_email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (trade == null) return 'Trade not found or already resolved';

      await _supabase
          .from('trades')
          .update({
            'status': 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tradeId);

      // Notify proposer
      await _supabase.from('trade_notifications').insert({
        'recipient_email': trade['proposer_email'],
        'type': 'trade_declined',
        'reference_id': tradeId,
        'reference_type': 'trade',
        'message': 'Your trade proposal was declined.',
      });

      debugPrint('✅ TradeService: trade declined → $tradeId');
      return 'success';
    } catch (e) {
      debugPrint('❌ TradeService.declineTrade error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Cancel a Trade ───────────────────────────────────────

  /// Cancel a pending trade (proposer action).
  static Future<String> cancelTrade(String tradeId) async {
    final email = _currentEmail;
    if (email == null) return 'Not logged in';

    try {
      final trade = await _supabase
          .from('trades')
          .select()
          .eq('id', tradeId)
          .eq('proposer_email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (trade == null) return 'Trade not found or already resolved';

      await _supabase
          .from('trades')
          .update({
            'status': 'cancelled',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tradeId);

      // Notify receiver
      await _supabase.from('trade_notifications').insert({
        'recipient_email': trade['receiver_email'],
        'type': 'trade_cancelled',
        'reference_id': tradeId,
        'reference_type': 'trade',
        'message': 'A trade proposal was cancelled.',
      });

      debugPrint('✅ TradeService: trade cancelled → $tradeId');
      return 'success';
    } catch (e) {
      debugPrint('❌ TradeService.cancelTrade error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Query Trades ─────────────────────────────────────────

  /// Get trades involving the current user, filtered by status.
  static Future<List<Trade>> getMyTrades({String? status}) async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      var query = _supabase
          .from('trades')
          .select()
          .or('proposer_email.eq.$email,receiver_email.eq.$email');

      if (status != null) {
        query = query.eq('status', status);
      }

      final rows = await query.order('proposed_at', ascending: false);
      return rows.map<Trade>((row) => Trade.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ TradeService.getMyTrades error: $e');
      return [];
    }
  }

  /// Get count of pending trades where user is the receiver (for badge).
  static Future<int> getPendingInboxCount() async {
    final email = _currentEmail;
    if (email == null) return 0;

    try {
      final rows = await _supabase
          .from('trades')
          .select('id')
          .eq('receiver_email', email)
          .eq('status', 'pending');

      return rows.length;
    } catch (e) {
      debugPrint('❌ TradeService.getPendingInboxCount error: $e');
      return 0;
    }
  }

  /// Get trades involving a specific character (for history).
  static Future<List<Trade>> getTradeHistory(String characterId) async {
    try {
      final rows = await _supabase
          .from('trades')
          .select()
          .eq('status', 'accepted')
          .or(
            'offered_character_id.eq.$characterId,requested_character_id.eq.$characterId',
          )
          .order('responded_at', ascending: false);

      return rows.map<Trade>((row) => Trade.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ TradeService.getTradeHistory error: $e');
      return [];
    }
  }

  // ─── Convenience aliases (used by UI screens) ────────────

  /// Get pending trades where current user is receiver.
  static Future<List<Trade>> getIncomingTrades() async {
    final email = _currentEmail;
    if (email == null) return [];
    final all = await getMyTrades(status: 'pending');
    return all.where((t) => t.receiverEmail == email).toList();
  }

  /// Get pending trades where current user is proposer.
  static Future<List<Trade>> getOutgoingTrades() async {
    final email = _currentEmail;
    if (email == null) return [];
    final all = await getMyTrades(status: 'pending');
    return all.where((t) => t.proposerEmail == email).toList();
  }

  /// Get all completed/declined/cancelled trades for current user.
  static Future<List<Trade>> getAllTradeHistory() async {
    final all = await getMyTrades();
    return all.where((t) => t.status != 'pending').toList();
  }
}
