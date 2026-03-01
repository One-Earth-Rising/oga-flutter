// ═══════════════════════════════════════════════════════════════════════
// LEND INBOX SCREEN — Sprint 12
// Tabbed: BORROWING | LENDING OUT | REQUESTS | HISTORY
// Shows active lends with return/recall and pending with accept/decline.
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/lend_service.dart';
import '../models/oga_character.dart';
import '../config/oga_storage.dart';
import '../widgets/oga_image.dart';

class LendInboxScreen extends StatefulWidget {
  const LendInboxScreen({super.key});

  @override
  State<LendInboxScreen> createState() => _LendInboxScreenState();
}

class _LendInboxScreenState extends State<LendInboxScreen>
    with SingleTickerProviderStateMixin {
  // ─── Heimdal palette ─────────────────────────────────
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);
  static const Color lendCyan = Color(0xFF80DEEA);

  late TabController _tabController;
  List<Lend> _borrowing = [];
  List<Lend> _lendingOut = [];
  List<Lend> _requests = [];
  List<Lend> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLends() async {
    setState(() => _loading = true);
    try {
      final borrowing = await LendService.getActiveBorrowing();
      final lendingOut = await LendService.getActiveLending();
      final requests = await LendService.getPendingRequests();
      final history = await LendService.getLendHistory();

      if (mounted) {
        setState(() {
          _borrowing = borrowing;
          _lendingOut = lendingOut;
          _requests = requests;
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load lends error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptLend(String lendId) async {
    final result = await LendService.acceptLend(lendId);
    if (result == 'success') {
      _loadLends();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lend accepted! Character added to your library.'),
            backgroundColor: lendCyan,
          ),
        );
      }
    } else {
      _showError(result);
    }
  }

  Future<void> _declineLend(String lendId) async {
    final result = await LendService.declineLend(lendId);
    if (result == 'success') {
      _loadLends();
    } else {
      _showError(result);
    }
  }

  Future<void> _returnCharacter(String lendId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: deepCharcoal,
        title: const Text(
          'RETURN CHARACTER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        content: const Text(
          'Return this character to its owner?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: lendCyan,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'RETURN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await LendService.returnLend(lendId);
      if (result == 'success') {
        _loadLends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Character returned!'),
              backgroundColor: neonGreen,
            ),
          );
        }
      } else {
        _showError(result);
      }
    }
  }

  Future<void> _recallCharacter(String lendId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: deepCharcoal,
        title: const Text(
          'RECALL CHARACTER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        content: const Text(
          'Recall this character early? The borrower will be notified.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'RECALL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await LendService.recallLend(lendId);
      if (result == 'success') {
        _loadLends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Character recalled!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _showError(result);
      }
    }
  }

  void _showError(String? msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg ?? 'Something went wrong'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  String _daysRemaining(DateTime? dueDate) {
    if (dueDate == null) return '';
    final diff = dueDate.toUtc().difference(DateTime.now().toUtc());
    if (diff.isNegative) return 'OVERDUE';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
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
          'LENDS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: lendCyan,
          indicatorWeight: 3,
          labelColor: lendCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          tabs: [
            Tab(
              text:
                  'BORROWING${_borrowing.isNotEmpty ? ' (${_borrowing.length})' : ''}',
            ),
            Tab(
              text:
                  'LENDING${_lendingOut.isNotEmpty ? ' (${_lendingOut.length})' : ''}',
            ),
            Tab(
              text:
                  'REQUESTS${_requests.isNotEmpty ? ' (${_requests.length})' : ''}',
            ),
            const Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: lendCyan))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLendList(_borrowing, _LendTab.borrowing),
                _buildLendList(_lendingOut, _LendTab.lendingOut),
                _buildLendList(_requests, _LendTab.requests),
                _buildLendList(_history, _LendTab.history),
              ],
            ),
    );
  }

  Widget _buildLendList(List<Lend> lends, _LendTab tab) {
    if (lends.isEmpty) {
      final messages = {
        _LendTab.borrowing: 'No characters borrowed',
        _LendTab.lendingOut: 'No characters lent out',
        _LendTab.requests: 'No pending lend requests',
        _LendTab.history: 'No lend history yet',
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_send,
              size: 48,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              messages[tab]!,
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
      color: lendCyan,
      backgroundColor: deepCharcoal,
      onRefresh: _loadLends,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lends.length,
        itemBuilder: (context, index) => _buildLendCard(lends[index], tab),
      ),
    );
  }

  Widget _buildLendCard(Lend lend, _LendTab tab) {
    final char = OGACharacter.fromId(lend.characterId);
    final durationDays = lend.durationHours ~/ 24;

    final otherParty = tab == _LendTab.borrowing || tab == _LendTab.requests
        ? lend.lenderEmail
        : lend.borrowerEmail;
    final otherName = otherParty.split('@').first;

    final remaining = _daysRemaining(lend.returnDueAt);
    final isOverdue = remaining == 'OVERDUE';

    Color statusColor;
    switch (lend.status) {
      case 'active':
        statusColor = lendCyan;
      case 'pending':
        statusColor = Colors.amber;
      case 'returned':
        statusColor = neonGreen;
      case 'recalled':
        statusColor = Colors.orange.shade400;
      case 'declined':
        statusColor = Colors.red.shade400;
      default:
        statusColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lend.isActive
              ? lendCyan.withValues(alpha: 0.3)
              : lend.isPending
              ? Colors.amber.withValues(alpha: 0.3)
              : ironGrey,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ironGrey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: char.imagePath.isNotEmpty
                        ? OgaImage(
                            path: OgaStorage.resolve(char.imagePath),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white24,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        char.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tab == _LendTab.borrowing || tab == _LendTab.requests
                            ? 'From $otherName'
                            : 'To $otherName',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                        lend.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (lend.isActive && remaining.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        remaining,
                        style: TextStyle(
                          color: isOverdue
                              ? Colors.red.shade400
                              : Colors.white54,
                          fontSize: 11,
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Duration info
            if (lend.isActive || lend.isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: voidBlack.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      durationDays > 0
                          ? '$durationDays day${durationDays == 1 ? '' : 's'} lend period'
                          : '${lend.durationHours}h lend period',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    if (lend.returnDueAt != null && lend.isActive) ...[
                      const Spacer(),
                      Text(
                        'Due ${_formatDate(lend.returnDueAt!)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Message
            if (lend.message != null && lend.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
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
                      '"${lend.message}"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Actions
            if (lend.isActive) ...[
              const SizedBox(height: 14),
              if (tab == _LendTab.borrowing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _returnCharacter(lend.id),
                    icon: const Icon(Icons.keyboard_return, size: 18),
                    label: const Text(
                      'RETURN CHARACTER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lendCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else if (tab == _LendTab.lendingOut)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _recallCharacter(lend.id),
                    icon: Icon(
                      Icons.replay,
                      size: 18,
                      color: Colors.orange.shade400,
                    ),
                    label: Text(
                      'RECALL EARLY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
            if (lend.isPending && tab == _LendTab.requests) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineLend(lend.id),
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptLend(lend.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lendCyan,
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

enum _LendTab { borrowing, lendingOut, requests, history }
