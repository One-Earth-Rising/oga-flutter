import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../modals/onboarding_detail_modal.dart';

// ─── Public Widget ───────────────────────────────────────────────────────────
//
// Drop this at the top of each tab's content column:
//
//   OnboardingProgressWidget(onNavigate: (route) { /* open settings etc */ })
//
// onNavigate is called with the step's actionRoute string so the parent screen
// can handle navigation (open settings modal, etc.)

class OnboardingProgressWidget extends StatefulWidget {
  final void Function(String route) onNavigate;

  const OnboardingProgressWidget({super.key, required this.onNavigate});

  @override
  State<OnboardingProgressWidget> createState() =>
      _OnboardingProgressWidgetState();
}

class _OnboardingProgressWidgetState extends State<OnboardingProgressWidget>
    with SingleTickerProviderStateMixin {
  final _service = OnboardingService();

  List<OnboardingFlowStatus>? _flows;
  bool _dismissed = false;

  // For the "REWARD CLAIMED → fade out" animation
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _showingRewardBadge = false;

  static const _neonGreen = Color(0xFF39FF14);
  static const _deepCharcoal = Color(0xFF121212);
  static const _ironGrey = Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _load();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final flows = await _service.loadAllFlows();
    if (!mounted) return;
    setState(() => _flows = flows);

    // If already complete on first load, skip straight to dismissed
    final allDone = flows.every((f) => f.isComplete);
    if (allDone) setState(() => _dismissed = true);
  }

  /// Called by the detail modal after the user completes a step so the bar
  /// refreshes without requiring a full page reload.
  Future<void> refresh() => _load();

  void _handleCompletionAnimation() async {
    setState(() => _showingRewardBadge = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _dismissed = true);
  }

  void _openDetail(OnboardingFlowStatus flow) {
    showOnboardingDetailModal(
      context: context,
      flowStatus: flow,
      onNavigate: widget.onNavigate,
      onRefresh: () async {
        await _load();
        // Check if now complete after refresh
        if (_flows != null && _flows!.every((f) => f.isComplete)) {
          _handleCompletionAnimation();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (_flows == null) return const SizedBox.shrink();

    // Only show flows that are incomplete (not yet started is still shown)
    final activeFlows = _flows!.where((f) => !f.isComplete).toList();
    if (activeFlows.isEmpty) {
      // Trigger animation if we haven't yet
      if (!_showingRewardBadge) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleCompletionAnimation(),
        );
      }
      return _buildRewardBadge();
    }

    if (_showingRewardBadge) return _buildRewardBadge();

    // Show the first incomplete flow
    final flow = activeFlows.first;
    return _buildBar(flow);
  }

  Widget _buildBar(OnboardingFlowStatus flow) {
    final pct = flow.progress;
    final completedCount = flow.completedCount;
    final totalCount = flow.totalCount;

    return GestureDetector(
      onTap: () => _openDetail(flow),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _deepCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _ironGrey, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + step count + chevron
            Row(
              children: [
                // Neon dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _neonGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flow.flow.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    color: _neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_right,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar track
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: _ironGrey,
                valueColor: const AlwaysStoppedAnimation<Color>(_neonGreen),
              ),
            ),
            const SizedBox(height: 6),
            // Reward hint
            Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(
                  'COMPLETE TO UNLOCK: ${flow.flow.rewardLabel}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardBadge() {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _deepCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _neonGreen.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: _neonGreen, size: 16),
            const SizedBox(width: 8),
            const Text(
              'REWARD CLAIMED — OGA SKIN UNLOCKED',
              style: TextStyle(
                color: _neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
