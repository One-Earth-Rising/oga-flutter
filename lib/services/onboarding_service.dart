import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Step Definition ────────────────────────────────────────────────────────

class OnboardingStep {
  final String id;
  final String label;
  final String description;
  final String actionLabel; // e.g. "ADD NAME"
  final String actionRoute; // e.g. 'settings' — caller handles navigation

  const OnboardingStep({
    required this.id,
    required this.label,
    required this.description,
    required this.actionLabel,
    required this.actionRoute,
  });
}

// ─── Flow Definition ────────────────────────────────────────────────────────

class OnboardingFlow {
  final String id;
  final String title;
  final String rewardLabel; // e.g. "OGA SKIN"
  final String rewardSubtitle;
  final List<OnboardingStep> steps;

  const OnboardingFlow({
    required this.id,
    required this.title,
    required this.rewardLabel,
    required this.rewardSubtitle,
    required this.steps,
  });
}

// ─── Step Status ────────────────────────────────────────────────────────────

class OnboardingStepStatus {
  final OnboardingStep step;
  final bool isComplete;

  const OnboardingStepStatus({required this.step, required this.isComplete});
}

// ─── Flow Status ────────────────────────────────────────────────────────────

class OnboardingFlowStatus {
  final OnboardingFlow flow;
  final List<OnboardingStepStatus> steps;

  const OnboardingFlowStatus({required this.flow, required this.steps});

  int get completedCount => steps.where((s) => s.isComplete).length;
  int get totalCount => steps.length;
  double get progress => totalCount == 0 ? 0.0 : completedCount / totalCount;
  bool get isComplete => completedCount == totalCount;
  bool get isStarted => completedCount > 0;
}

// ─── Flow Registry ──────────────────────────────────────────────────────────

const OnboardingFlow kProfileFlow = OnboardingFlow(
  id: 'profile_setup',
  title: 'COMPLETE YOUR PROFILE',
  rewardLabel: 'OGA SKIN',
  rewardSubtitle: 'Exclusive reward for founding members',
  steps: [
    OnboardingStep(
      id: 'name',
      label: 'ADD YOUR NAME',
      description: 'Let the community know who you are.',
      actionLabel: 'ADD NAME',
      actionRoute: 'settings',
    ),
    OnboardingStep(
      id: 'username',
      label: 'SET A USERNAME',
      description: 'Claim your unique @handle.',
      actionLabel: 'SET USERNAME',
      actionRoute: 'settings',
    ),
    OnboardingStep(
      id: 'avatar',
      label: 'UPLOAD A PHOTO',
      description: 'Put a face to your legend.',
      actionLabel: 'UPLOAD PHOTO',
      actionRoute: 'settings',
    ),
    OnboardingStep(
      id: 'bio',
      label: 'WRITE YOUR BIO',
      description: 'Tell the world what you\'re about.',
      actionLabel: 'ADD BIO',
      actionRoute: 'settings',
    ),
  ],
);

// Flow 2 — wired up in a future sprint
// const OnboardingFlow kCommunityFlow = OnboardingFlow(
//   id: 'community_engagement',
//   title: 'JOIN THE COMMUNITY',
//   rewardLabel: 'LEGEND BADGE',
//   rewardSubtitle: 'For those who build the network',
//   steps: [
//     OnboardingStep(id: 'invite_3', label: 'INVITE 3 FRIENDS', ...),
//     OnboardingStep(id: 'first_lend', label: 'LEND A CHARACTER', ...),
//     OnboardingStep(id: 'first_trade', label: 'PROPOSE A TRADE', ...),
//   ],
// );

// ─── Service ────────────────────────────────────────────────────────────────

class OnboardingService {
  final _supabase = Supabase.instance.client;

  /// Returns all registered flows with completion status for the current user.
  /// Add new flows to the list below as features ship.
  Future<List<OnboardingFlowStatus>> loadAllFlows() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('profiles')
        .select('first_name, last_name, username, avatar_url, bio')
        .eq('email', user.email!)
        .maybeSingle();

    if (response == null) return [];

    return [
      _evaluateProfileFlow(response),
      // _evaluateCommunityFlow(friendCount, lendCount, tradeCount),
    ];
  }

  OnboardingFlowStatus _evaluateProfileFlow(Map<String, dynamic> profile) {
    bool _notEmpty(dynamic val) =>
        val != null && val.toString().trim().isNotEmpty;

    final statuses = [
      OnboardingStepStatus(
        step: kProfileFlow.steps[0], // name
        isComplete:
            _notEmpty(profile['first_name']) || _notEmpty(profile['last_name']),
      ),
      OnboardingStepStatus(
        step: kProfileFlow.steps[1], // username
        isComplete: _notEmpty(profile['username']),
      ),
      OnboardingStepStatus(
        step: kProfileFlow.steps[2], // avatar
        isComplete: _notEmpty(profile['avatar_url']),
      ),
      OnboardingStepStatus(
        step: kProfileFlow.steps[3], // bio
        isComplete: _notEmpty(profile['bio']),
      ),
    ];

    return OnboardingFlowStatus(flow: kProfileFlow, steps: statuses);
  }
}
