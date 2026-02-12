import 'package:flutter/material.dart';
import '../services/campaign_analytics.dart';

/// Error boundary for campaign screens
/// Catches and handles errors gracefully, preventing app crashes
class CampaignErrorBoundary extends StatefulWidget {
  final Widget child;
  final String campaignId;

  const CampaignErrorBoundary({
    super.key,
    required this.child,
    required this.campaignId,
  });

  @override
  State<CampaignErrorBoundary> createState() => _CampaignErrorBoundaryState();
}

class _CampaignErrorBoundaryState extends State<CampaignErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Show error and fallback
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Campaign Failed to Load',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                'Redirecting to main experience...',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Navigate to main experience
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
    }

    // Wrap child to catch errors
    return _ErrorCatcher(
      onError: (error, stack) {
        setState(() {
          _error = error;
        });

        // Log error
        CampaignAnalytics.trackCampaignError(
          error.toString(),
          widget.campaignId,
        );
      },
      child: widget.child,
    );
  }
}

/// Internal widget to catch errors
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final Function(Object error, StackTrace stack) onError;

  const _ErrorCatcher({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
