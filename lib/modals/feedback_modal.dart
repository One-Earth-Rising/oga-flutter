import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/feedback_service.dart';
import '../services/analytics_service.dart';

/// Beta feedback form modal with auto-screenshot capture.
/// Accessible from: settings sidebar, dashboard FAB, avatar dropdown.
/// Stores to Supabase feedback table.
///
/// Screenshot setup:
///   Wrap your main content with `FeedbackModal.wrapForScreenshot(child: ...)`
///   to enable auto-capture. The modal captures the wrapped content BEFORE
///   the dialog opens, so screenshots show the user's actual context.
class FeedbackModal extends StatefulWidget {
  final String? pageContext;
  final Uint8List? screenshotBytes;

  const FeedbackModal({super.key, this.pageContext, this.screenshotBytes});

  // ── Screenshot capture infrastructure ─────────────────────
  /// Global key for the RepaintBoundary wrapper.
  /// Used by _captureScreen() to reliably capture the current view.
  static final GlobalKey _repaintKey = GlobalKey();

  /// Wrap your main content with this to enable screenshot capture.
  /// Place this around the Scaffold body or the main content area.
  ///
  /// Example in dashboard:
  /// ```dart
  /// body: FeedbackModal.wrapForScreenshot(child: _buildBody(isMobile)),
  /// ```
  static Widget wrapForScreenshot({required Widget child}) {
    return RepaintBoundary(key: _repaintKey, child: child);
  }

  /// Show the feedback modal with auto-screenshot.
  static Future<void> show(BuildContext context, {String? pageContext}) async {
    // ── Step 1: Capture screenshot BEFORE modal opens ──
    Uint8List? screenshotBytes;
    try {
      screenshotBytes = await _captureScreen();
      if (screenshotBytes != null) {
        debugPrint('📸 Screenshot captured: ${screenshotBytes.length} bytes');
      } else {
        debugPrint(
          '⚠️ Screenshot capture returned null (RepaintBoundary may not be set up)',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Screenshot capture failed (non-blocking): $e');
    }

    if (!context.mounted) return;

    // ── Step 2: Show modal with captured bytes ──
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      await showModalBottomSheet(
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
            child: FeedbackModal(
              pageContext: pageContext,
              screenshotBytes: screenshotBytes,
            ),
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: FeedbackModal(
            pageContext: pageContext,
            screenshotBytes: screenshotBytes,
          ),
        ),
      ),
    );
  }

  /// Capture the current screen using the GlobalKey RepaintBoundary.
  /// Returns null if the wrapper isn't set up or capture fails.
  static Future<Uint8List?> _captureScreen() async {
    try {
      final context = _repaintKey.currentContext;
      if (context == null) {
        debugPrint(
          '⚠️ RepaintBoundary key has no context — '
          'wrap your content with FeedbackModal.wrapForScreenshot()',
        );
        return null;
      }

      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('⚠️ Could not find RenderRepaintBoundary');
        return null;
      }

      // Capture at 1x pixel ratio to keep file size reasonable (~100-300KB)
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('⚠️ Screen capture error: $e');
      return null;
    }
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
  bool _includeScreenshot = true;

  final _categories = [
    {'id': 'bug', 'label': 'BUG REPORT', 'icon': Icons.bug_report_outlined},
    {'id': 'feature', 'label': 'FEATURE', 'icon': Icons.lightbulb_outline},
    {'id': 'ux', 'label': 'UX / DESIGN', 'icon': Icons.brush_outlined},
    {'id': 'other', 'label': 'OTHER', 'icon': Icons.chat_bubble_outline},
  ];

  bool get _hasScreenshot => widget.screenshotBytes != null;

  @override
  void initState() {
    super.initState();
    // Rebuild when text changes so submit button updates
    _messageCtrl.addListener(() => setState(() {}));
  }

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
      constraints: const BoxConstraints(maxHeight: 680),
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
          const SizedBox(height: 16),

          // ── Screenshot status row ────────────────────────
          _buildScreenshotRow(),
          const SizedBox(height: 16),

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

  /// Screenshot status row — shows thumbnail + toggle when captured,
  /// or a "no screenshot" message when capture wasn't available.
  Widget _buildScreenshotRow() {
    if (_hasScreenshot) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: deepCharcoal,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _includeScreenshot
                ? neonGreen.withValues(alpha: 0.25)
                : ironGrey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail preview
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                widget.screenshotBytes!,
                width: 48,
                height: 32,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(width: 10),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 12,
                        color: _includeScreenshot
                            ? neonGreen.withValues(alpha: 0.6)
                            : Colors.white24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _includeScreenshot
                            ? 'SCREENSHOT ATTACHED'
                            : 'SCREENSHOT EXCLUDED',
                        style: TextStyle(
                          color: _includeScreenshot
                              ? Colors.white70
                              : Colors.white30,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _includeScreenshot
                        ? 'A screenshot of your current view will be submitted'
                        : 'Screenshot will not be included',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _includeScreenshot = !_includeScreenshot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _includeScreenshot
                      ? neonGreen.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _includeScreenshot
                        ? neonGreen.withValues(alpha: 0.3)
                        : ironGrey,
                  ),
                ),
                child: Text(
                  _includeScreenshot ? 'INCLUDED' : 'EXCLUDED',
                  style: TextStyle(
                    color: _includeScreenshot ? neonGreen : Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No screenshot available
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ironGrey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 12,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 6),
          Text(
            'No screenshot captured',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 10,
              fontWeight: FontWeight.w600,
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

  bool get _canSubmit => _messageCtrl.text.trim().length >= 5 && !_isSubmitting;

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    // ── Upload screenshot if included ──
    String? screenshotUrl;
    if (_includeScreenshot && widget.screenshotBytes != null) {
      screenshotUrl = await FeedbackService.uploadScreenshot(
        widget.screenshotBytes!,
      );
      if (screenshotUrl != null) {
        debugPrint('📸 Screenshot uploaded: $screenshotUrl');
      } else {
        debugPrint('⚠️ Screenshot upload failed (submitting without it)');
      }
    }

    final success = await FeedbackService.submit(
      category: _category,
      message: _messageCtrl.text.trim(),
      pageContext: widget.pageContext,
      screenshotUrl: screenshotUrl,
    );

    // Track the feedback event
    AnalyticsService.trackFeedbackSubmitted(_category);

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
