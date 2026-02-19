import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class LiveNetlifyChatbot extends StatefulWidget {
  final String widgetUrl;
  final VoidCallback onComplete;

  const LiveNetlifyChatbot({
    super.key,
    required this.widgetUrl,
    required this.onComplete,
  });

  @override
  State<LiveNetlifyChatbot> createState() => _LiveNetlifyChatbotState();
}

class _LiveNetlifyChatbotState extends State<LiveNetlifyChatbot> {
  StreamSubscription? _messageSubscription;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    debugPrint('🤖 Chatbot loading from: ${widget.widgetUrl}');

    // Register the iframe view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('netlify-chatbot-view', (
      int viewId,
    ) {
      final iframe = html.IFrameElement()
        ..src = widget.widgetUrl
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%'
        // Mobile compatibility attributes
        ..setAttribute('allow', 'clipboard-read; clipboard-write')
        ..setAttribute('allowfullscreen', 'true')
        ..setAttribute('loading', 'eager')
        // Prevent iOS Safari bouncing/scrolling issues
        ..setAttribute('scrolling', 'yes');

      // Listen for iframe load event
      iframe.onLoad.listen((_) {
        debugPrint('✅ Chatbot iframe loaded successfully');
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      });

      // Listen for iframe error
      iframe.onError.listen((event) {
        debugPrint('❌ Chatbot iframe failed to load');
        if (mounted) {
          setState(() => _hasError = true);
        }
      });

      return iframe;
    });

    // Listen for messages from the chatbot iframe
    _messageSubscription = html.window.onMessage.listen((event) {
      debugPrint('📩 Received message from chatbot: ${event.data}');

      // Handle simple string message
      if (event.data == "ONBOARDING_COMPLETE") {
        debugPrint('✅ Onboarding complete (simple message)');
        widget.onComplete();
        return;
      }

      // Handle structured message with session_id
      if (event.data is String) {
        try {
          final data = jsonDecode(event.data as String);

          if (data['type'] == 'ONBOARDING_REDIRECT') {
            final sessionId =
                data['userData']?['sessionId'] ?? data['sessionId'];

            debugPrint(
              '🎯 Navigating to welcome screen with session: $sessionId',
            );

            if (sessionId != null && mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/welcome',
                arguments: {'sessionId': sessionId},
              );
            } else {
              debugPrint('⚠️ No session ID found, falling back to library');
              widget.onComplete();
            }
          } else if (data['type'] == 'ONBOARDING_COMPLETE') {
            debugPrint('✅ Onboarding complete (structured message)');
            widget.onComplete();
          }
        } catch (e) {
          debugPrint('⚠️ Could not parse message: $e');
        }
      }
    });

    // Timeout fallback — if iframe hasn't loaded after 10 seconds, show error
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_isLoaded && !_hasError) {
        debugPrint('⏱️ Chatbot load timeout — showing fallback');
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorFallback();
    }

    return Stack(
      children: [
        const HtmlElementView(viewType: 'netlify-chatbot-view'),
        // Show loading indicator until iframe loads
        if (!_isLoaded)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Color(0xFF39FF14),
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '> CONNECTING...',
                    style: TextStyle(
                      color: Color(0xFF39FF14),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Fallback UI if iframe fails to load (mobile Safari issues, network errors, etc.)
  Widget _buildErrorFallback() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Chat couldn\'t load',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap below to try again or sign in directly',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                // Retry by rebuilding widget
                setState(() {
                  _hasError = false;
                  _isLoaded = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF39FF14)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: Color(0xFF39FF14),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
