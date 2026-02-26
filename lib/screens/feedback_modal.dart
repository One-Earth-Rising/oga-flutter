import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../services/analytics_service.dart';

/// Beta feedback form modal.
/// Accessible from: settings sidebar, dashboard FAB, avatar dropdown.
/// Stores to Supabase feedback table.
class FeedbackModal extends StatefulWidget {
  final String? pageContext; // Which screen the user is on

  const FeedbackModal({super.key, this.pageContext});

  /// Show the feedback modal.
  static Future<void> show(BuildContext context, {String? pageContext}) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: FeedbackModal(pageContext: pageContext),
          ),
        ),
      );
    }

    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: FeedbackModal(pageContext: pageContext),
        ),
      ),
    );
  }

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color ironGrey = Color(0xFF2C2C2C);

  final _messageCtrl = TextEditingController();
  String _category = 'bug';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final _categories = [
    {'id': 'bug', 'label': 'BUG REPORT', 'icon': Icons.bug_report_outlined},
    {'id': 'feature', 'label': 'FEATURE', 'icon': Icons.lightbulb_outline},
    {'id': 'ux', 'label': 'UX / DESIGN', 'icon': Icons.brush_outlined},
    {'id': 'other', 'label': 'OTHER', 'icon': Icons.chat_bubble_outline},
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return _buildContent(isMobile: true);
    }

    return Container(
      width: 480,
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ironGrey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildContent(isMobile: false),
      ),
    );
  }

  Widget _buildContent({required bool isMobile}) {
    if (_isSubmitted) return _buildSuccessState(isMobile: isMobile);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SEND FEEDBACK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (!isMobile)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Help us improve OGA during beta.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Category selector
          const Text(
            'CATEGORY',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isActive = _category == cat['id'];
              return GestureDetector(
                onTap: () => setState(() => _category = cat['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? neonGreen.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isActive ? neonGreen : ironGrey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 14,
                        color: isActive ? neonGreen : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color: isActive ? neonGreen : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Message field
          const Text(
            'YOUR FEEDBACK',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ironGrey),
            ),
            child: TextField(
              controller: _messageCtrl,
              maxLines: 5,
              minLines: 3,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              decoration: InputDecoration(
                hintText: _category == 'bug'
                    ? 'Describe the bug: what happened, what you expected, steps to reproduce...'
                    : _category == 'feature'
                    ? 'What feature would make OGA better for you?'
                    : 'Share your thoughts...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit button
          GestureDetector(
            onTap: _canSubmit ? _handleSubmit : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _canSubmit ? neonGreen : ironGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'SUBMIT FEEDBACK',
                        style: TextStyle(
                          color: _canSubmit ? Colors.black : Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.check, color: neonGreen, size: 28),
          ),
          const SizedBox(height: 20),
          const Text(
            'FEEDBACK RECEIVED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thanks for helping us improve OGA. We review all feedback.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ironGrey),
              ),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool get _canSubmit =>
      _messageCtrl.text.trim().length >= 10 && !_isSubmitting;

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    final success = await FeedbackService.submit(
      category: _category,
      message: _messageCtrl.text.trim(),
      pageContext: widget.pageContext,
    );

    // Track the feedback event
    await AnalyticsService.trackFeedback(_category);

    setState(() {
      _isSubmitting = false;
      if (success) _isSubmitted = true;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit feedback. Please try again.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
