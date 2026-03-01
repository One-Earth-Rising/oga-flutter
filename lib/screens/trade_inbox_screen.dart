// ═══════════════════════════════════════════════════════════════════════
// TRADE INBOX SCREEN — Sprint 12
// Tabbed: INCOMING | OUTGOING | HISTORY
// Shows trade proposals with accept/decline/cancel actions.
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/trade_service.dart';
import '../models/oga_character.dart';
import '../config/oga_storage.dart';
import '../widgets/oga_image.dart';

class TradeInboxScreen extends StatefulWidget {
  const TradeInboxScreen({super.key});

  @override
  State<TradeInboxScreen> createState() => _TradeInboxScreenState();
}

class _TradeInboxScreenState extends State<TradeInboxScreen>
    with SingleTickerProviderStateMixin {
  // ─── Heimdal palette ─────────────────────────────────
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  late TabController _tabController;
  List<Trade> _incoming = [];
  List<Trade> _outgoing = [];
  List<Trade> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrades();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrades() async {
    setState(() => _loading = true);
    try {
      final incoming = await TradeService.getIncomingTrades();
      final outgoing = await TradeService.getOutgoingTrades();
      final history = await TradeService.getAllTradeHistory();

      if (mounted) {
        setState(() {
          _incoming = incoming;
          _outgoing = outgoing;
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load trades error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptTrade(String tradeId) async {
    final result = await TradeService.acceptTrade(tradeId);
    if (result == 'success') {
      _loadTrades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade accepted!'),
            backgroundColor: neonGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  Future<void> _declineTrade(String tradeId) async {
    final result = await TradeService.declineTrade(tradeId);
    if (result == 'success') {
      _loadTrades();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red.shade400),
      );
    }
  }

  Future<void> _cancelTrade(String tradeId) async {
    final result = await TradeService.cancelTrade(tradeId);
    if (result == 'success') {
      _loadTrades();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red.shade400),
      );
    }
  }

  String _timeAgo(DateTime date) {
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
          'TRADES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: neonGreen,
          indicatorWeight: 3,
          labelColor: neonGreen,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          tabs: [
            Tab(
              text:
                  'INCOMING${_incoming.isNotEmpty ? ' (${_incoming.length})' : ''}',
            ),
            Tab(
              text:
                  'OUTGOING${_outgoing.isNotEmpty ? ' (${_outgoing.length})' : ''}',
            ),
            const Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTradeList(_incoming, TradeListType.incoming),
                _buildTradeList(_outgoing, TradeListType.outgoing),
                _buildTradeList(_history, TradeListType.history),
              ],
            ),
    );
  }

  Widget _buildTradeList(List<Trade> trades, TradeListType type) {
    if (trades.isEmpty) {
      String message;
      switch (type) {
        case TradeListType.incoming:
          message = 'No incoming trade requests';
        case TradeListType.outgoing:
          message = 'No outgoing trade proposals';
        case TradeListType.history:
          message = 'No trade history yet';
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 48,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: neonGreen,
      backgroundColor: deepCharcoal,
      onRefresh: _loadTrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trades.length,
        itemBuilder: (context, index) => _buildTradeCard(trades[index], type),
      ),
    );
  }

  Widget _buildTradeCard(Trade trade, TradeListType type) {
    final offeredChar = OGACharacter.fromId(trade.offeredCharacterId);
    final requestedChar = OGACharacter.fromId(trade.requestedCharacterId);

    final otherParty = type == TradeListType.incoming
        ? trade.proposerEmail
        : trade.receiverEmail;
    final otherName = otherParty.split('@').first;
    final timeStr = _timeAgo(trade.proposedAt);

    Color statusColor;
    switch (trade.status) {
      case 'pending':
        statusColor = Colors.amber;
      case 'accepted':
        statusColor = neonGreen;
      case 'declined':
        statusColor = Colors.red.shade400;
      case 'cancelled':
        statusColor = Colors.orange.shade400;
      default:
        statusColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: trade.isPending ? neonGreen.withValues(alpha: 0.3) : ironGrey,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: other party + status + time
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ironGrey,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == TradeListType.incoming
                            ? 'From $otherName'
                            : 'To $otherName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trade.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Trade visual: offered ↔ requested
            Row(
              children: [
                Expanded(
                  child: _buildMiniCharCard(
                    type == TradeListType.incoming
                        ? offeredChar
                        : requestedChar,
                    type == TradeListType.incoming ? 'THEY GIVE' : 'YOU GET',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.swap_horiz,
                    color: neonGreen.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
                Expanded(
                  child: _buildMiniCharCard(
                    type == TradeListType.incoming
                        ? requestedChar
                        : offeredChar,
                    type == TradeListType.incoming ? 'THEY WANT' : 'YOU GIVE',
                  ),
                ),
              ],
            ),
            // Message
            if (trade.message != null && trade.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: voidBlack.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${trade.message}"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Action buttons (only for pending)
            if (trade.isPending) ...[
              const SizedBox(height: 14),
              if (type == TradeListType.incoming)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _declineTrade(trade.id),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400),
                          foregroundColor: Colors.red.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'DECLINE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptTrade(trade.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (type == TradeListType.outgoing)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelTrade(trade.id),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade400),
                      foregroundColor: Colors.orange.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CANCEL TRADE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCharCard(OGACharacter char, String label) {
    return Container(
      decoration: BoxDecoration(
        color: voidBlack.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: ironGrey.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: char.imagePath.isNotEmpty
                ? OgaImage(
                    path: OgaStorage.resolve(char.imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : const Center(
                    child: Icon(Icons.person, color: Colors.white24, size: 28),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              char.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

enum TradeListType { incoming, outgoing, history }
