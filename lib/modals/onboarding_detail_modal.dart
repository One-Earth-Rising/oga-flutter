import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';

// ─── Entry Point ─────────────────────────────────────────────────────────────

void showOnboardingDetailModal({
  required BuildContext context,
  required OnboardingFlowStatus flowStatus,
  required void Function(String route) onNavigate,
  required Future<void> Function() onRefresh,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (ctx, anim, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _OnboardingDetailModal(
      flowStatus: flowStatus,
      onNavigate: onNavigate,
      onRefresh: onRefresh,
    ),
  );
}

// ─── Modal ───────────────────────────────────────────────────────────────────

class _OnboardingDetailModal extends StatelessWidget {
  final OnboardingFlowStatus flowStatus;
  final void Function(String route) onNavigate;
  final Future<void> Function() onRefresh;

  static const _neonGreen = Color(0xFF39FF14);
  static const _deepCharcoal = Color(0xFF121212);
  static const _ironGrey = Color(0xFF2C2C2C);
  static const _surface = Color(0xFF1A1A1A);

  const _OnboardingDetailModal({
    required this.flowStatus,
    required this.onNavigate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 520 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 0 : 16,
            vertical: 32,
          ),
          child: Material(
            color: _deepCharcoal,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressSummary(),
                          const SizedBox(height: 20),
                          _buildStepsList(context),
                          const SizedBox(height: 20),
                          _buildRewardCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _ironGrey, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _neonGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              flowStatus.flow.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final pct = flowStatus.progress;
    final label = flowStatus.isComplete
        ? 'COMPLETE'
        : '${flowStatus.completedCount} OF ${flowStatus.totalCount} STEPS DONE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: flowStatus.isComplete ? _neonGreen : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                color: _neonGreen,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: _ironGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(_neonGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: flowStatus.steps.map((s) => _buildStepRow(context, s)).toList(),
    );
  }

  Widget _buildStepRow(BuildContext context, OnboardingStepStatus status) {
    final isDone = status.isComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDone ? _neonGreen.withValues(alpha: 0.3) : _ironGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Check / empty circle
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? _neonGreen : Colors.transparent,
              border: isDone
                  ? null
                  : Border.all(color: Colors.white24, width: 1.5),
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.black, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.step.label,
                  style: TextStyle(
                    color: isDone ? Colors.white70 : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white30,
                  ),
                ),
                if (!isDone) ...[
                  const SizedBox(height: 2),
                  Text(
                    status.step.description,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action button (only on incomplete steps)
          if (!isDone) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onNavigate(status.step.actionRoute);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _neonGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.step.actionLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    final isUnlocked = flowStatus.isComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? _neonGreen.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? _neonGreen.withValues(alpha: 0.4) : _ironGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Reward icon placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _neonGreen.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnlocked
                    ? _neonGreen.withValues(alpha: 0.4)
                    : _ironGrey,
                width: 1,
              ),
            ),
            child: Icon(
              isUnlocked ? Icons.star : Icons.lock_outline,
              color: isUnlocked ? _neonGreen : Colors.white24,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnlocked ? 'REWARD UNLOCKED' : 'COMPLETION REWARD',
                  style: TextStyle(
                    color: isUnlocked ? _neonGreen : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  flowStatus.flow.rewardLabel,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  flowStatus.flow.rewardSubtitle,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
